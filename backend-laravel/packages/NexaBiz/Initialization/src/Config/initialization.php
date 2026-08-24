<?php

namespace NexaBiz\Initialization\Config;

return [
    // Entity types considered part of a company's initialization snapshot.
    // Everything else (transactions, customers, products...) arrives through
    // the normal incremental sync API after initialization completes.
    'master_entity_types' => [
        'company_profile',
        'account',
        'fiscal_year',
        'currency_rate',
        'product',
        'inventory_item',
        'inventory_movement',
        'customer',
        'supplier',
        'sale',
        'purchase',
        'financial_transaction',
        'journal_entry',
        'fund_transfer',
        'currency_conversion',
    ],

    // Maximum rows per bootstrap/data page.
    'page_size' => (int) env('BOOTSTRAP_PAGE_SIZE', 500),
];
