{% macro procurement_review_rules(e) -%}
unnest([
    struct(
        'OFFER_DATA_COMPLETENESS' as review_type,
        {{ e }}.action_count >= 50 and {{ e }}.offer_count_coverage_percent < 70 as meets_rule,
        if({{ e }}.offer_count_coverage_percent < 35, 'HIGH', 'MEDIUM') as priority,
        'Offer-count coverage / all agency actions' as evidence_metric,
        {{ e }}.offer_count_coverage_percent as evidence_percent,
        {{ e }}.action_count - {{ e }}.usable_offer_count_actions as supporting_record_count,
        'Sample missing or invalid offer-count records and check reporting / ingestion rules before using competition comparisons.' as recommended_next_step,
        'Missing offers are unknown, not zero. Review reporting practices before interpreting the statistic.' as interpretation_guardrail
    ),
    struct(
        'SINGLE_OFFER_REVIEW' as review_type,
        {{ e }}.actions_with_at_least_one_offer >= 50
            and {{ e }}.offer_count_coverage_percent >= 70
            and {{ e }}.single_offer_percent >= 50 as meets_rule,
        if({{ e }}.single_offer_percent >= 65, 'HIGH', 'MEDIUM') as priority,
        'Single-offer share / actions reporting >=1 offer' as evidence_metric,
        {{ e }}.single_offer_percent as evidence_percent,
        {{ e }}.actions_with_at_least_one_offer as supporting_record_count,
        'Sample solicitations and award records; check procurement method, applicable exceptions and market context.' as recommended_next_step,
        'Single-offer awards do not establish unlawful or ineffective competition.' as interpretation_guardrail
    ),
    struct(
        'SUPPLIER_CONCENTRATION_REVIEW' as review_type,
        {{ e }}.action_count >= 50 and {{ e }}.funding_increases > 0
            and {{ e }}.identified_positive_suppliers >= 3
            and {{ e }}.unknown_supplier_funding_share_percent <= 20
            and {{ e }}.leading_supplier_funding_share_percent >= 35 as meets_rule,
        if({{ e }}.leading_supplier_funding_share_percent >= 50, 'HIGH', 'MEDIUM')
            as priority,
        'Largest identified supplier / all agency funding increases' as evidence_metric,
        {{ e }}.leading_supplier_funding_share_percent as evidence_percent,
        {{ e }}.identified_positive_suppliers as supporting_record_count,
        'Review category, contract and supplier concentration; assess alternatives only with procurement-owner context.' as recommended_next_step,
        'Concentration may be justified; short-window obligations are not evidence of vendor risk or poor value.' as interpretation_guardrail
    ),
    struct(
        'FUNDING_CHANGE_REVIEW' as review_type,
        {{ e }}.action_count >= 50 and {{ e }}.funding_increases > 0
            and {{ e }}.funding_reduction_to_increase_percent >= 20 as meets_rule,
        if({{ e }}.funding_reduction_to_increase_percent >= 40, 'HIGH', 'MEDIUM')
            as priority,
        'Funding reductions / funding increases' as evidence_metric,
        {{ e }}.funding_reduction_to_increase_percent as evidence_percent,
        {{ e }}.action_count as supporting_record_count,
        'Review large modifications and funding adjustments; reconcile the reasons with procurement and finance owners.' as recommended_next_step,
        'Funding reductions are contract actions, not automatically savings or evidence of control failure.' as interpretation_guardrail
    )
])
{%- endmacro %}
