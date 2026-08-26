<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('plans', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name', 200);
            $table->string('code', 100)->unique('uq_plans_code');
            $table->text('description')->nullable();
            $table->decimal('price', 10, 2)->default(0.00);
            $table->string('currency', 10)->default('USD');
            $table->string('billing_interval', 50)->default('monthly');
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->boolean('is_free')->default(false);
            $table->integer('default_trial_days')->default(0);
            $table->timestampsTz();
        });

        Schema::create('packages', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name', 200);
            $table->string('code', 100)->unique('uq_packages_code');
            $table->string('category', 100)->default('core');
            $table->text('description')->nullable();
            $table->decimal('price', 10, 2)->default(0.00);
            $table->string('currency', 10)->default('USD');
            $table->string('billing_interval', 50)->default('monthly');
            $table->boolean('is_addon')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();
        });

        Schema::create('features', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('package_id');
            $table->string('name', 200);
            $table->string('code', 100)->unique('uq_features_code');
            $table->string('capability_code', 100);
            $table->text('description')->nullable();
            $table->timestampsTz();

            $table->foreign('package_id')->references('id')->on('packages')->onDelete('cascade');
        });

        Schema::create('plan_packages', function (Blueprint $table) {
            $table->uuid('plan_id');
            $table->uuid('package_id');
            $table->boolean('is_included')->default(true);
            $table->timestampsTz();

            $table->primary(['plan_id', 'package_id']);
            $table->foreign('plan_id')->references('id')->on('plans')->onDelete('cascade');
            $table->foreign('package_id')->references('id')->on('packages')->onDelete('cascade');
        });

        Schema::create('package_dependencies', function (Blueprint $table) {
            $table->uuid('package_id');
            $table->uuid('depends_on_package_id');
            $table->timestampTz('created_at')->useCurrent();

            $table->primary(['package_id', 'depends_on_package_id']);
            $table->foreign('package_id')->references('id')->on('packages')->onDelete('cascade');
            $table->foreign('depends_on_package_id')->references('id')->on('packages')->onDelete('cascade');
        });

        Schema::create('package_limits', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('package_id');
            $table->string('limit_key', 100);
            $table->integer('default_value')->default(0);
            $table->string('period', 50)->default('unlimited');
            $table->timestampsTz();

            $table->foreign('package_id')->references('id')->on('packages')->onDelete('cascade');
        });

        Schema::create('subscriptions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('company_id');
            $table->uuid('plan_id');
            $table->string('status', 50)->default('free');
            $table->timestampTz('starts_at');
            $table->timestampTz('ends_at')->nullable();
            $table->timestampTz('trial_ends_at')->nullable();
            $table->timestampTz('grace_ends_at')->nullable();
            $table->timestampTz('cancelled_at')->nullable();
            $table->timestampsTz();

            $table->foreign('company_id')->references('id')->on('companies')->onDelete('cascade');
            $table->foreign('plan_id')->references('id')->on('plans');
        });

        Schema::create('subscription_items', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('subscription_id');
            $table->uuid('package_id');
            $table->string('status', 50)->default('active');
            $table->boolean('is_addon')->default(true);
            $table->integer('quantity')->default(1);
            $table->timestampTz('starts_at');
            $table->timestampTz('ends_at')->nullable();
            $table->timestampsTz();

            $table->foreign('subscription_id')->references('id')->on('subscriptions')->onDelete('cascade');
            $table->foreign('package_id')->references('id')->on('packages');
        });

        Schema::create('company_entitlements', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('company_id')->unique('uq_company_entitlement');
            $table->uuid('subscription_id');
            $table->json('snapshot_data');
            $table->string('checksum', 64);
            $table->timestampTz('verified_at');
            $table->timestampTz('expires_at')->nullable();
            $table->timestampsTz();

            $table->foreign('company_id')->references('id')->on('companies')->onDelete('cascade');
            $table->foreign('subscription_id')->references('id')->on('subscriptions')->onDelete('cascade');
        });

        Schema::create('usage_meters', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('company_id');
            $table->string('meter_key', 100);
            $table->integer('current_value')->default(0);
            $table->integer('max_limit')->default(0);
            $table->string('reset_period', 50)->default('monthly');
            $table->timestampTz('last_reset_at')->nullable();
            $table->timestampsTz();

            $table->unique(['company_id', 'meter_key'], 'uq_usage_meters_company_key');
            $table->foreign('company_id')->references('id')->on('companies')->onDelete('cascade');
        });

        Schema::create('subscription_events', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('company_id');
            $table->uuid('subscription_id');
            $table->string('event_type', 100);
            $table->json('payload');
            $table->string('idempotency_key', 255)->unique('uq_subscription_events_key');
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('company_id')->references('id')->on('companies')->onDelete('cascade');
            $table->foreign('subscription_id')->references('id')->on('subscriptions')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_events');
        Schema::dropIfExists('usage_meters');
        Schema::dropIfExists('company_entitlements');
        Schema::dropIfExists('subscription_items');
        Schema::dropIfExists('subscriptions');
        Schema::dropIfExists('package_limits');
        Schema::dropIfExists('package_dependencies');
        Schema::dropIfExists('plan_packages');
        Schema::dropIfExists('features');
        Schema::dropIfExists('packages');
        Schema::dropIfExists('plans');
    }
};
