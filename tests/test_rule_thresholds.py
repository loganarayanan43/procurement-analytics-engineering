"""Pure-Python specification boundary examples; NOT BigQuery SQL execution."""
import unittest


def decision(actions, coverage, offers_with_count, single_share, identified_suppliers, unknown_share,
             largest_share, increases, reductions):
    rules = {}
    if actions >= 50 and coverage < 70:
        rules['OFFER_DATA_COMPLETENESS'] = 'HIGH' if coverage < 35 else 'MEDIUM'
    if offers_with_count >= 50 and coverage >= 70 and single_share >= 50:
        rules['SINGLE_OFFER_REVIEW'] = 'HIGH' if single_share >= 65 else 'MEDIUM'
    if (actions >= 50 and increases > 0 and identified_suppliers >= 3 and
            unknown_share <= 20 and largest_share >= 35):
        rules['SUPPLIER_CONCENTRATION_REVIEW'] = 'HIGH' if largest_share >= 50 else 'MEDIUM'
    if actions >= 50 and increases > 0 and reductions/increases*100 >= 20:
        rules['FUNDING_CHANGE_REVIEW'] = 'HIGH' if reductions/increases*100 >= 40 else 'MEDIUM'
    return rules

class BoundarySpecificationTests(unittest.TestCase):
    def setUp(self):
        self.base=dict(actions=50, coverage=80, offers_with_count=50, single_share=10,
                       identified_suppliers=3, unknown_share=0, largest_share=10,
                       increases=100, reductions=0)
    def d(self, **changes):
        p=self.base|changes
        return decision(**p)
    def test_offer_coverage(self):
        self.assertEqual(self.d(coverage=34.999)['OFFER_DATA_COMPLETENESS'],'HIGH')
        self.assertEqual(self.d(coverage=35)['OFFER_DATA_COMPLETENESS'],'MEDIUM')
        self.assertNotIn('OFFER_DATA_COMPLETENESS',self.d(coverage=70))
        self.assertNotIn('OFFER_DATA_COMPLETENESS',self.d(actions=49,coverage=5))
    def test_single_offer(self):
        self.assertEqual(self.d(single_share=50)['SINGLE_OFFER_REVIEW'],'MEDIUM')
        self.assertEqual(self.d(single_share=65)['SINGLE_OFFER_REVIEW'],'HIGH')
        self.assertNotIn('SINGLE_OFFER_REVIEW',self.d(single_share=90,coverage=69.99))
        self.assertNotIn('SINGLE_OFFER_REVIEW',self.d(single_share=90,offers_with_count=49))
    def test_supplier_concentration(self):
        self.assertEqual(self.d(largest_share=35)['SUPPLIER_CONCENTRATION_REVIEW'],'MEDIUM')
        self.assertEqual(self.d(largest_share=50)['SUPPLIER_CONCENTRATION_REVIEW'],'HIGH')
        self.assertNotIn('SUPPLIER_CONCENTRATION_REVIEW',self.d(largest_share=60,unknown_share=20.001))
        self.assertNotIn('SUPPLIER_CONCENTRATION_REVIEW',self.d(largest_share=60,identified_suppliers=2))
    def test_funding_reduction(self):
        self.assertEqual(self.d(reductions=20)['FUNDING_CHANGE_REVIEW'],'MEDIUM')
        self.assertEqual(self.d(reductions=40)['FUNDING_CHANGE_REVIEW'],'HIGH')
        self.assertNotIn('FUNDING_CHANGE_REVIEW',self.d(reductions=19.99))
        self.assertNotIn('FUNDING_CHANGE_REVIEW',self.d(increases=0))

if __name__ == '__main__': unittest.main()
