<?php

namespace App\Http\Controllers\Purchase;

use App\Enums\PurchaseStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Purchase\StorePurchaseRequest;
use App\Models\Category;
use App\Models\Product;
use App\Models\Purchase;
use App\Models\PurchaseDetails;
use App\Models\Supplier;
use Carbon\Carbon;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xls;

class PurchaseController extends Controller
{
    public function index()
    {
        $purchases = DB::select("SELECT * FROM recent_purchases");

        return view('purchases.index', compact('purchases'));
    }

    public function approvedPurchases()
    {

        $purchases = DB::select("SELECT * FROM approved_purchases");

        return view('purchases.approved-purchases', compact('purchases'));
    }


    public function pendingPurchases()
    {
        $purchases = DB::select("SELECT * FROM pending_purchases");

        return view('purchases.pending', compact('purchases'));

    }


    public function show(Purchase $purchase)
    {
        $purchase->loadMissing(['supplier', 'details', 'createdBy', 'updatedBy'])->get();

        $products = PurchaseDetails::where('purchase_id', $purchase->id)->get();

        return view('purchases.details-purchase', [
            'purchase' => $purchase,
            'products' => $products
        ]);

    }



    public function showPercheas(Purchase $purchase)
    {
        // Load purchase details using raw SQL

        // Load purchase data with supplier and user information using the stored procedure
        $purchaseData = DB::select("CALL GetPurchaseDetails(?)", [$purchase->id]);

        // Load product details for the specific purchase using the stored procedure
        $products = DB::select("CALL GetPurchaseProductDetails(?)", [$purchase->id]);

        // Assuming there's only one purchase data row returned
        $purchase = (object) $purchaseData[0]; // Casting to object to mimic Eloquent behavior

        return view('purchases.details-purchase', [
            'purchase' => $purchase,
            'products' => $products
        ]);
    }

    public function edit(Purchase $purchase)
    {
        // N+1 Problem if load 'createdBy', 'updatedBy',
        $purchase->with(['supplier', 'details'])->get();

        return view('purchases.edit', [
            'purchase' => $purchase,
        ]);
    }




    public function editPurchase(Purchase $purchase)
    {
        // Call stored procedure to retrieve purchase data with supplier and user information
        $purchaseData = DB::select("CALL GetPurchaseDetailsById(?)", [$purchase->id]);

        // Call stored procedure to retrieve purchase details with product information
        $purchaseDetails = DB::select("CALL GetPurchaseDetailsByPurchaseId(?)", [$purchase->id]);

        // Assuming there's only one purchase data row returned
        $purchase = (object) $purchaseData[0]; // Casting to object to mimic Eloquent behavior

        return view('purchases.edit', [
            'purchase' => $purchase,
            'details' => $purchaseDetails,
        ]);
    }


    public function create()
    {

        $categories = DB::select("SELECT * FROM view_categories;");


        $suppliers = DB::select("SELECT * FROM view_suppliers;");

        return view('purchases.create', [
            'categories' => $categories,
            'suppliers' => $suppliers,
        ]);

    }

    public function store(StorePurchaseRequest $request)
    {
        $purchase = Purchase::create($request->all());

        /*
         * TODO: Must validate that
         */
        if (! $request->invoiceProducts == null) {
            $pDetails = [];

            foreach ($request->invoiceProducts as $product) {
                $pDetails['purchase_id'] = $purchase['id'];
                $pDetails['product_id'] = $product['product_id'];
                $pDetails['quantity'] = $product['quantity'];
                $pDetails['unitcost'] = $product['unitcost'];
                $pDetails['total'] = $product['total'];
                $pDetails['created_at'] = Carbon::now();

                //PurchaseDetails::insert($pDetails);
                $purchase->details()->insert($pDetails);
            }
        }

        return redirect()
            ->route('purchases.index')
            ->with('success', 'Purchase has been created!');
    }


    public function storePurchase(StorePurchaseRequest $request)
    {
        // Call stored procedure to insert into the purchases table
        DB::statement("CALL InsertPurchase(?, ?, ?, ?, ?, ?)", [
            $request->input('supplier_id'),
            $request->input('date'),
            $request->input('purchase_no'),
            $request->input('status'),
            $request->input('total_amount'),
            $request->input('created_by')
        ]);

        //  Get the last inserted ID for the purchase
        $purchaseId = DB::getPdo()->lastInsertId();

        //Check if invoiceProducts is not null and insert into purchase_details using stored procedure
        if ($request->has('invoiceProducts') && !empty($request->invoiceProducts)) {
            foreach ($request->invoiceProducts as $product) {
                // Validate that product_id, quantity, unitcost, and total are present
                if (isset($product['product_id'], $product['quantity'], $product['unitcost'], $product['total'])) {
                    DB::statement("CALL InsertPurchaseDetail(?, ?, ?, ?, ?, ?)", [
                        $purchaseId,
                        $product['product_id'],
                        $product['quantity'],
                        $product['unitcost'],
                        $product['total'],
                        Carbon::now() //
                    ]);
                }
            }
        }

        return redirect()
            ->route('purchases.index')
            ->with('success', 'Purchase has been created!');
    }


    // public function update(Purchase $purchase, Request $request)
    // {
    //     $products = PurchaseDetails::where('purchase_id', $purchase->id)->get();

    //     foreach ($products as $product) {
    //         Product::where('id', $product->product_id)
    //             ->update(['quantity' => DB::raw('quantity+'.$product->quantity)]);
    //     }

    //     Purchase::findOrFail($purchase->id)
    //         ->update([
    //             //'purchase_status' => 1, // 1 = approved, 0 = pending
    //             'status' => PurchaseStatus::APPROVED,
    //             'updated_by' => auth()->user()->id,
    //         ]);

    //     return redirect()
    //         ->route('purchases.index')
    //         ->with('success', 'Purchase has been approved!');
    // }



    public function update(Purchase $purchase, Request $request)
    {

        $products = DB::select("SELECT * FROM purchase_details WHERE purchase_id = ?", [$purchase->id]);

        foreach ($products as $product) {
            DB::statement("CALL UpdateProductQuantity(?, ?)", [
                $product->quantity,  // The quantity to add to the product
                $product->product_id // The product ID
            ]);
        }


        DB::statement("CALL UpdatePurchaseStatus(?, ?, ?)", [
            PurchaseStatus::APPROVED->value, // Use the value of the enum (1 for approved)
            auth()->user()->id,             // The user who is updating
            $purchase->id                   // The purchase ID to update
        ]);


        return redirect()
            ->route('purchases.index')
            ->with('success', 'Purchase has been approved!');
    }


    // public function destroy(Purchase $purchase)
    // {
    //     $purchase->delete();

    //     return redirect()
    //         ->route('purchases.index')
    //         ->with('success', 'Purchase has been deleted!');
    // }

    public function destroy(Purchase $purchase)
{
    // Delete the purchase record using a raw SQL query
    DB::statement("CALL DeletePurchaseById(?)", [$purchase->id]);

    //  Redirect with success message
    return redirect()
        ->route('purchases.index')
        ->with('success', 'Purchase has been deleted!');
}

    // public function dailyPurchaseReport()
    // {
    //     $purchases = Purchase::with(['supplier'])
    //         //->where('purchase_status', 1)
    //         ->where('date', today()->format('Y-m-d'))->get();

    //     return view('purchases.daily-report', [
    //         'purchases' => $purchases,
    //     ]);
    // }

    public function dailyPurchaseReport()
    {
        // $purchases = DB::select("
        //     SELECT p.*, s.name as supplier_name
        //     FROM purchases p
        //     LEFT JOIN suppliers s ON p.supplier_id = s.id
        //     WHERE p.date = ?", [today()->format('Y-m-d')]);

        $purchases = DB::select("CALL GetDailyPurchaseReport(?)", [today()->format('Y-m-d')]);

        return view('purchases.daily-report', [
            'purchases' => $purchases,
        ]);

        dd($purchases);
    }

    public function getPurchaseReport()
    {
        return view('purchases.report-purchase');
    }

    // public function exportPurchaseReport(Request $request)
    // {
    //     $rules = [
    //         'start_date' => 'required|string|date_format:Y-m-d',
    //         'end_date' => 'required|string|date_format:Y-m-d',
    //     ];

    //     $validatedData = $request->validate($rules);

    //     $sDate = $validatedData['start_date'];
    //     $eDate = $validatedData['end_date'];

    //     $purchases = DB::table('purchase_details')
    //         ->join('products', 'purchase_details.product_id', '=', 'products.id')
    //         ->join('purchases', 'purchase_details.purchase_id', '=', 'purchases.id')
    //         ->join('users', 'users.id', '=', 'purchases.created_by')
    //         ->whereBetween('purchases.purchase_date', [$sDate, $eDate])
    //         ->where('purchases.purchase_status', '1')
    //         ->select('purchases.purchase_no', 'purchases.purchase_date', 'purchases.supplier_id', 'products.code', 'products.name', 'purchase_details.quantity', 'purchase_details.unitcost', 'purchase_details.total', 'users.name as created_by')
    //         ->get();

    //     dd($purchases);

    //     $purchase_array[] = [
    //         'Date',
    //         'No Purchase',
    //         'Supplier',
    //         'Product Code',
    //         'Product',
    //         'Quantity',
    //         'Unitcost',
    //         'Total',
    //         'Created By'
    //     ];

    //     foreach ($purchases as $purchase) {
    //         $purchase_array[] = [
    //             'Date' => $purchase->purchase_date,
    //             'No Purchase' => $purchase->purchase_no,
    //             'Supplier' => $purchase->supplier_id,
    //             'Product Code' => $purchase->product_code,
    //             'Product' => $purchase->product_name,
    //             'Quantity' => $purchase->quantity,
    //             'Unitcost' => $purchase->unitcost,
    //             'Total' => $purchase->total,
    //         ];
    //     }

    //     $this->exportExcel($purchase_array);
    // }

    // public function exportExcel($products)
    // {
    //     ini_set('max_execution_time', 0);
    //     ini_set('memory_limit', '4000M');

    //     try {
    //         $spreadSheet = new Spreadsheet();
    //         $spreadSheet->getActiveSheet()->getDefaultColumnDimension()->setWidth(20);
    //         $spreadSheet->getActiveSheet()->fromArray($products);
    //         $Excel_writer = new Xls($spreadSheet);
    //         header('Content-Type: application/vnd.ms-excel');
    //         header('Content-Disposition: attachment;filename="purchase-report.xls"');
    //         header('Cache-Control: max-age=0');
    //         ob_end_clean();
    //         $Excel_writer->save('php://output');
    //         exit();
    //     } catch (Exception $e) {
    //         return $e;
    //     }
    // }
}
