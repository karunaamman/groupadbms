<?php

namespace App\Http\Controllers\Dashboards;

use Illuminate\Support\Facades\DB;
use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\Purchase;
use App\Models\Quotation;

class DashboardController extends Controller
{
    public function index()
    {
        $orders = DB::select("SELECT * FROM order_count_view")[0]->count;
        $completedOrders = DB::select("SELECT * FROM completed_orders_count")[0]->count;
        $products = DB::select("SELECT * FROM products_count")[0]->count;
        $purchases = DB::select("SELECT * FROM purchases_count")[0]->count;
        $todayPurchases = DB::select("SELECT * FROM today_purchases_count")[0]->count;
        $categories = DB::select("SELECT * FROM categories_count")[0]->count;
        $quotations = DB::select("SELECT * FROM quotations_count")[0]->count;
        $todayQuotations = DB::select("SELECT * FROM today_quotations_count")[0]->count;

        return view('dashboard', [
            'products' => $products,
            'orders' => $orders,
            'completedOrders' => $completedOrders,
            'purchases' => $purchases,
            'todayPurchases' => $todayPurchases,
            'categories' => $categories,
            'quotations' => $quotations,
            'todayQuotations' => $todayQuotations,
        ]);
    }
}
