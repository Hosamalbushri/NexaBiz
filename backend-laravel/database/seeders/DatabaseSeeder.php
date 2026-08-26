<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use NexaBiz\Entitlements\Database\Seeders\EntitlementSeeder;
use NexaBiz\Identity\Database\Seeders\IdentitySeeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $this->call(IdentitySeeder::class);
        $this->call(EntitlementSeeder::class);
        $this->call(PlanSeeder::class);
        $this->call(SubscribedCompanySeeder::class);
    }
}
