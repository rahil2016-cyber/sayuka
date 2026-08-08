<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('seeker_package_purchases', function (Blueprint $table) {
            $table->string('phonepe_merchant_order_id', 64)->nullable()->after('razorpay_signature');
            $table->string('phonepe_order_id', 128)->nullable()->after('phonepe_merchant_order_id');
            $table->string('phonepe_transaction_id', 128)->nullable()->after('phonepe_order_id');
            $table->index('phonepe_merchant_order_id');
        });

        Schema::table('company_subscription_payments', function (Blueprint $table) {
            $table->string('phonepe_merchant_order_id', 64)->nullable()->after('razorpay_signature');
            $table->string('phonepe_order_id', 128)->nullable()->after('phonepe_merchant_order_id');
            $table->string('phonepe_transaction_id', 128)->nullable()->after('phonepe_order_id');
            $table->index('phonepe_merchant_order_id');
        });
    }

    public function down(): void
    {
        Schema::table('seeker_package_purchases', function (Blueprint $table) {
            $table->dropIndex(['phonepe_merchant_order_id']);
            $table->dropColumn([
                'phonepe_merchant_order_id',
                'phonepe_order_id',
                'phonepe_transaction_id',
            ]);
        });

        Schema::table('company_subscription_payments', function (Blueprint $table) {
            $table->dropIndex(['phonepe_merchant_order_id']);
            $table->dropColumn([
                'phonepe_merchant_order_id',
                'phonepe_order_id',
                'phonepe_transaction_id',
            ]);
        });
    }
};
