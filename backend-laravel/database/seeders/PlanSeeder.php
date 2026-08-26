<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use NexaBiz\Entitlements\Database\Seeders\PlanSeeder as PackagePlanSeeder;

class PlanSeeder extends Seeder
{
    public function run(): void
    {
        $this->call(PackagePlanSeeder::class);
    }
}
