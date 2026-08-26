<?php

namespace NexaBiz\Entitlements\Services;

use NexaBiz\Entitlements\Models\Package;

class PackageResolver
{
    public function resolveDependencies(array $requestedPackageCodes): array
    {
        $resolved = array_flip($requestedPackageCodes);

        $packages = Package::with('dependencies')
            ->whereIn('code', $requestedPackageCodes)
            ->get();

        foreach ($packages as $pkg) {
            foreach ($pkg->dependencies as $dep) {
                if (! isset($resolved[$dep->code])) {
                    $resolved[$dep->code] = true;
                }
            }
        }

        return array_keys($resolved);
    }
}
