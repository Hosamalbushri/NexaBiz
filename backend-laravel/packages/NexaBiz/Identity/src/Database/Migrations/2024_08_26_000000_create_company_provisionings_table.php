<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('company_provisionings', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('local_company_id')->index();
            $table->uuid('server_company_id')->nullable()->index();
            $table->uuid('user_id')->index();
            $table->string('status')->default('PROVISIONING');
            $table->string('idempotency_key')->nullable()->unique();
            $table->text('error_message')->nullable();
            $table->timestamps();

            $table->foreign('server_company_id')
                ->references('id')
                ->on('companies')
                ->onDelete('cascade');

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('company_provisionings');
    }
};
