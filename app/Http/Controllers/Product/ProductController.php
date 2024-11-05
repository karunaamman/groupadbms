<?php

namespace App\Http\Controllers\Product;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\Controller;
use App\Http\Requests\Product\StoreProductRequest;
use App\Http\Requests\Product\UpdateProductRequest;
use App\Models\Category;
use App\Models\Product;
use App\Models\Unit;
use Illuminate\Http\Request;
use Picqer\Barcode\BarcodeGeneratorHTML;

class ProductController extends Controller
{
    public function index()
    {
        $products = collect(DB::select("SELECT id, name FROM products LIMIT 1"));


        return view('products.index', [
            'products' => $products,
        ]);
    }

    public function create(Request $request)
    {
        $categories = collect(DB::select("SELECT id, name FROM categories"));
        $units = collect(DB::select("SELECT id, name FROM units"));


        if ($request->has('category')) {
            $slug = $request->get('category');
$categories = collect(DB::select("SELECT * FROM categories WHERE slug = ?", [$slug]));

        }

        if ($request->has('unit')) {
            $slug = $request->get('unit');
            $units = DB::select("SELECT * FROM units WHERE slug = ?", [$slug]);            
        }

        return view('products.create', [
            'categories' => $categories,
            'units' => $units,
        ]);
    }

    public function store(StoreProductRequest $request)
    {

        $productData = $request->all(); // Get all data from the request

        $product=DB::insert("INSERT INTO products (
    name,
    category_id,
    unit_id,
    buying_price,
    selling_price,
    quantity,
    quantity_alert,
    tax,
    tax_type,
    notes,
    slug,
    code
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [
    $productData['name'],
    $productData['category_id'],
    $productData['unit_id'],
    $productData['buying_price'],
    $productData['selling_price'],
    $productData['quantity'],
    $productData['quantity_alert'],
    $productData['tax'],
    $productData['tax_type'],
    $productData['notes'],
    $productData['slug'],
    $productData['code'],
]);

//$product = Product::create($request->all());

        /**
         * Handle upload image
         */
        if ($request->hasFile('product_image')) {
            $file = $request->file('product_image');
            $filename = hexdec(uniqid()) . '.' . $file->getClientOriginalExtension();

            $file->storeAs('products/', $filename, 'public');
            ////////////////////////////////////////////////////////////////////
            $product->update([
                'product_image' => $filename
            ]);
            //////////////////////////////////////////
        }

        return redirect()
            ->back()
            ->with('success', 'Product has been created!');
    }

    public function show(Product $product)
    {
        // Generate a barcode
        $generator = new BarcodeGeneratorHTML();

        $barcode = $generator->getBarcode($product->code, $generator::TYPE_CODE_128);

        return view('products.show', [
            'product' => $product,
            'barcode' => $barcode,
        ]);
    }

    public function edit(Product $product)
    {
        return view('products.edit', [
            'categories' => Category::all(),
            'units' => Unit::all(),
            'product' => $product
        ]);
    }

    public function update(UpdateProductRequest $request, Product $product)
    {
        $product->update($request->except('product_image'));

        if ($request->hasFile('product_image')) {

            // Delete Old Photo
            if ($product->product_image) {
                unlink(public_path('storage/products/') . $product->product_image);
            }

            // Prepare New Photo
            $file = $request->file('product_image');
            $fileName = hexdec(uniqid()) . '.' . $file->getClientOriginalExtension();

            // Store an image to Storage
            $file->storeAs('products/', $fileName, 'public');

            // Save DB
            $product->update([
                'product_image' => $fileName
            ]);
        }

        return redirect()
            ->route('products.index')
            ->with('success', 'Product has been updated!');
    }

    public function destroy(Product $product)
    {
        /**
         * Delete photo if exists.
         */
        if ($product->product_image) {
            unlink(public_path('storage/products/') . $product->product_image);
        }

        $product->delete();

        return redirect()
            ->route('products.index')
            ->with('success', 'Product has been deleted!');
    }
}
