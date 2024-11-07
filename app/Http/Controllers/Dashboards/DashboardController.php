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
    $monthly_order = collect(DB::select("select * from vw_MonthlyOrders"));
    $monthly_purchase = collect(DB::select("select * from vw_MonthlyPurchases"));
    $orders = DB::select("SELECT fn_OrdersCount()")[0]->{"fn_OrdersCount()"};
    $completedOrders = DB::select("SELECT fn_CompletedOrdersCount()")[0]->{"fn_CompletedOrdersCount()"};
    $products = DB::select("SELECT fn_ProductCount()")[0]->{"fn_ProductCount()"};
    $purchases = DB::select("SELECT fn_PurchasesCount()")[0]->{"fn_PurchasesCount()"};
    $todayPurchases = DB::select("SELECT fn_TodayPurchasesCount()")[0]->{"fn_TodayPurchasesCount()"};
    $categories = DB::select("SELECT fn_CategoriesCount()")[0]->{"fn_CategoriesCount()"};
    $quotations = DB::select("SELECT fn_QuotationsCount()")[0]->{"fn_QuotationsCount()"};
    $todayQuotations = DB::select("SELECT fn_TodayQuotationsCount()")[0]->{"fn_TodayQuotationsCount()"};

    return view('dashboard', [
        'products' => $products,
        'orders' => $orders,
        'completedOrders' => $completedOrders,
        'purchases' => $purchases,
        'todayPurchases' => $todayPurchases,
        'categories' => $categories,
        'quotations' => $quotations,
        'todayQuotations' => $todayQuotations,
        'monthlyorder'=>  $monthly_order,
        'monthly_purchase'=>  $monthly_purchase,
    ]);
}
}
