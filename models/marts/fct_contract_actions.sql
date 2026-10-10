{{ config(materialized='table') }}

select
    contract_transaction_unique_key as transaction_id,
    contract_award_unique_key as contract_id,
    award_id_piid,
    modification_number,
    transaction_number,
    parent_award_agency_id,
    parent_award_id_piid,

    coalesce(concat('uei:', recipient_uei), 'unknown')
        as supplier_key,

    -- agency_key represents the awarding agency.
    coalesce(concat('agency:', awarding_agency_code), 'unknown')
        as agency_key,
    coalesce(concat('agency:', funding_agency_code), 'unknown')
        as funding_agency_key,

    action_date as date_key,
    federal_action_obligation as obligation_amount,
    funding_change_type,
    number_of_offers_received,
    is_offer_count_missing,
    is_offer_count_invalid,

    recipient_uei is null as is_supplier_identifier_missing,
    awarding_agency_code is null as is_agency_identifier_missing,
    funding_agency_code is null
        as is_funding_agency_identifier_missing,

    awarding_sub_agency_code,
    awarding_sub_agency_name,

    recipient_country_code,
    recipient_state_code,
    recipient_city_name,

    award_type_code,
    award_type,
    action_type_code,
    action_type,
    extent_competed,
    naics_code,
    naics_description,
    product_or_service_code,
    product_or_service_code_description,
    usaspending_permalink

from {{ ref('int_contract_actions') }}
