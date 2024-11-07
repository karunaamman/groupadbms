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
        $purchases = DB::select("SELECT * FROM purchases ORDER BY created_at DESC");

        return view('purchases.index', compact('purchases'));
    }

    public function approvedPurchases()
    {
        // $purchases = Purchase::with(['supplier'])
        //     ->where('status', PurchaseStatus::APPROVED)->get(); // 1 = approved\

        //     // dd($purchases);

        // return view('purchases.approved-purchases', [
        //     'purchases' => $purchases,
        // ]);

        $approvedStatus = PurchaseStatus::PENDING->value;

        $purchases = DB::select("SELECT purchases.*, suppliers.name AS supplier_name
                                 FROM purchases
                                 JOIN suppliers ON purchases.supplier_id = suppliers.id
                                 WHERE purchases.status = ?", [$approvedStatus]);

        // dd($purchases);

        return view('purchases.approved-purchases', compact('purchases'));
    }


    public function show(Purchase $purchase)
    {
        $purchase->loadMissing(['supplier', 'details', 'createdBy', 'updatedBy'])->get();

        $products = PurchaseDetails::where('purchase_id', $purchase->id)->get();

        return view('purchases.details-purchase', [
            'purchase' => $purchase,
            'products' => $products
        ]);

        // Main purchase record with its relationships using raw SQL

        // dd($products);

    }



// public function show(Purchase $purchase)
// {
//     // Load purchase details using raw SQL
//     $purchaseData = DB::select("
//         SELECT p.*, s.name AS supplier_name, u1.name AS created_by_name, u2.name AS updated_by_name
//         FROM purchases p
//         LEFT JOIN suppliers s ON p.supplier_id = s.id
//         LEFT JOIN users u1 ON p.created_by = u1.id
//         LEFT JOIN users u2 ON p.updated_by = u2.id
//         WHERE p.id = ?
//     ", [$purchase->id]);

//     // Load purchase details
//     $products = DB::select("
//         SELECT pd.*, pr.name AS product_name, pr.code AS product_code, pr.product_image
//         FROM purchase_details pd
//         LEFT JOIN products pr ON pd.product_id = pr.id
//         WHERE pd.purchase_id = ?
//     ", [$purchase->id]);

//     // Assuming there's only one purchase data row returned
//     $purchase = (object) $purchaseData[0]; // Casting to object to mimic Eloquent behavior

//     // return view('purchases.details-purchase', [
//     //     'purchase' => $purchase,
//     //     'products' => $products
//     // ]);

//     dd($purchase,$products);
// }






    public function edit(Purchase $purchase)
    {
        // N+1 Problem if load 'createdBy', 'updatedBy',
        $purchase->with(['supplier', 'details'])->get();

        return view('purchases.edit', [
            'purchase' => $purchase,
        ]);
    }

    public function create()
    {
        // return view('purchases.create', [
        //     'categories' => Category::select(['id', 'name'])->get(),
        //     'suppliers' => Supplier::select(['id', 'name'])->get(),
        // ]);
        $categories = DB::select("SELECT id, name FROM categories");

        // Fetch suppliers with raw SQL
        $suppliers = DB::select("SELECT id, name FROM suppliers");

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


    // public function store(Request $request)
    // {
    //     // Validate input data
    //     // $request->validate([
    //     //     'purchase_no' => 'required|string|max:255',
    //     //     'purchase_date' => 'required|date',
    //     //     'supplier_id' => 'required|integer',
    //     //     'created_by' => 'required|integer',
    //     //     'updated_by' => 'nullable|integer',
    //     //     'status' => 'required|boolean',
    //     //     'total_amount' => 'required|numeric',
    //     //     'invoiceProducts.*.product_id' => 'required|integer',
    //     //     'invoiceProducts.*.quantity' => 'required|integer',
    //     //     'invoiceProducts.*.unitcost' => 'required|numeric',
    //     //     'invoiceProducts.*.total' => 'required|numeric',
    //     // ]);

    //     // try {
    //     //     // Insert the main purchase record using raw SQL
    //     //     DB::insert("
    //     //         INSERT INTO purchases (purchase_no, purchase_date, supplier_id, created_by, updated_by, status, total_amount, created_at, updated_at)
    //     //         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    //     //     ", [
    //     //         $request->purchase_no,
    //     //         $request->purchase_date,
    //     //         $request->supplier_id,
    //     //         $request->created_by,
    //     //         $request->updated_by,
    //     //         $request->status,
    //     //         $request->total_amount,
    //     //         Carbon::now(),
    //     //         Carbon::now()
    //     //     ]);

    //     //     // Get the ID of the newly inserted purchase record
    //     //     $purchaseId = DB::getPdo()->lastInsertId();

    //     //     // Check and insert purchase details if invoiceProducts are provided
    //     //     if ($request->invoiceProducts) {
    //     //         $values = [];
    //     //         foreach ($request->invoiceProducts as $product) {
    //     //             $values[] = "($purchaseId, {$product['product_id']}, {$product['quantity']}, {$product['unitcost']}, {$product['total']}, '" . Carbon::now() . "', '" . Carbon::now() . "')";
    //     //         }

    //     //         // Execute the SQL to insert multiple rows into `purchase_details`
    //     //         $valuesString = implode(", ", $values);
    //     //         DB::statement("
    //     //             INSERT INTO purchase_details (purchase_id, product_id, quantity, unitcost, total, created_at, updated_at)
    //     //             VALUES $valuesString
    //     //         ");
    //     //     }

    //     //     return redirect()->route('purchases.index')->with('success', 'Purchase has been created!');
    //     // } catch (\Exception $e) {
    //     //     // Handle any errors and rollback if necessary
    //     //     return redirect()->back()->withErrors('An error occurred while creating the purchase: ' . $e->getMessage());
    //     // }
    // }





    public function update(Purchase $purchase, Request $request)
    {
        $products = PurchaseDetails::where('purchase_id', $purchase->id)->get();

        foreach ($products as $product) {
            Product::where('id', $product->product_id)
                ->update(['quantity' => DB::raw('quantity+'.$product->quantity)]);
        }

        Purchase::findOrFail($purchase->id)
            ->update([
                //'purchase_status' => 1, // 1 = approved, 0 = pending
                'status' => PurchaseStatus::APPROVED,
                'updated_by' => auth()->user()->id,
            ]);

        return redirect()
            ->route('purchases.index')
            ->with('success', 'Purchase has been approved!');
    }

    public function destroy(Purchase $purchase)
    {
        $purchase->delete();

        return redirect()
            ->route('purchases.index')
            ->with('success', 'Purchase has been deleted!');
    }

    public function dailyPurchaseReport()
    {
        $purchases = Purchase::with(['supplier'])
            //->where('purchase_status', 1)
            ->where('date', today()->format('Y-m-d'))->get();

        return view('purchases.daily-report', [
            'purchases' => $purchases,
        ]);
    }

    public function getPurchaseReport()
    {
        return view('purchases.report-purchase');
    }

    public function exportPurchaseReport(Request $request)
    {
        $rules = [
            'start_date' => 'required|string|date_format:Y-m-d',
            'end_date' => 'required|string|date_format:Y-m-d',
        ];

        $validatedData = $request->validate($rules);

        $sDate = $validatedData['start_date'];
        $eDate = $validatedData['end_date'];

        $purchases = DB::table('purchase_details')
            ->join('products', 'purchase_details.product_id', '=', 'products.id')
            ->join('purchases', 'purchase_details.purchase_id', '=', 'purchases.id')
            ->join('users', 'users.id', '=', 'purchases.created_by')
            ->whereBetween('purchases.purchase_date', [$sDate, $eDate])
            ->where('purchases.purchase_status', '1')
            ->select('purchases.purchase_no', 'purchases.purchase_date', 'purchases.supplier_id', 'products.code', 'products.name', 'purchase_details.quantity', 'purchase_details.unitcost', 'purchase_details.total', 'users.name as created_by')
            ->get();

        dd($purchases);

        $purchase_array[] = [
            'Date',
            'No Purchase',
            'Supplier',
            'Product Code',
            'Product',
            'Quantity',
            'Unitcost',
            'Total',
            'Created By'
        ];

        foreach ($purchases as $purchase) {
            $purchase_array[] = [
                'Date' => $purchase->purchase_date,
                'No Purchase' => $purchase->purchase_no,
                'Supplier' => $purchase->supplier_id,
                'Product Code' => $purchase->product_code,
                'Product' => $purchase->product_name,
                'Quantity' => $purchase->quantity,
                'Unitcost' => $purchase->unitcost,
                'Total' => $purchase->total,
            ];
        }

        $this->exportExcel($purchase_array);
    }

    public function exportExcel($products)
    {
        ini_set('max_execution_time', 0);
        ini_set('memory_limit', '4000M');

        try {
            $spreadSheet = new Spreadsheet();
            $spreadSheet->getActiveSheet()->getDefaultColumnDimension()->setWidth(20);
            $spreadSheet->getActiveSheet()->fromArray($products);
            $Excel_writer = new Xls($spreadSheet);
            header('Content-Type: application/vnd.ms-excel');
            header('Content-Disposition: attachment;filename="purchase-report.xls"');
            header('Cache-Control: max-age=0');
            ob_end_clean();
            $Excel_writer->save('php://output');
            exit();
        } catch (Exception $e) {
            return $e;
        }
    }
}
