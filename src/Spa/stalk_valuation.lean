import Spa.rat_open_data_completion
import valuation.field

/-!
# The valuation on the stalk

We define the valuations on the stalks of the structure presheaf of the adic spectrum
-/

local attribute [instance, priority 0] classical.prop_decidable

open topological_space valuation Spv spa uniform_space

namespace spa.presheaf
variable {A : Huber_pair}

-- We need this search depth because of the following scary instance
set_option class.instance_max_depth 100

local attribute [instance] uniform_space'

/--The underlying function of the valuation on the stalk of the structure presheaf.-/
noncomputable def stalk_to_valuation_field (x : spa A) :
  stalk_of_rings (spa.presheaf_of_topological_rings A).to_presheaf_of_rings x →
  completion (valuation_field (Spv.out x.1)) :=
to_stalk.rec (spa.presheaf_of_topological_rings A).to_presheaf_of_rings x
  (completion (valuation_field (Spv.out x.1))) (λ U hxU, to_valuation_field_completion hxU)
  (λ U V HUV r hxU, (to_valuation_field_completion_commutes hxU HUV r).symm)

instance stalk_to_valuation_field.is_ring_hom (x : spa A) :
  is_ring_hom (stalk_to_valuation_field x) := to_stalk.rec_is_ring_hom _ _ _ _ _

/--The valuation on the stalk of the structure presheaf of the adic spectrum.-/
noncomputable def stalk_valuation (x : spa A) :
  valuation (stalk_of_rings (spa.presheaf_of_topological_rings A).to_presheaf_of_rings x)
    (value_monoid (out x.1)) :=
(valuation_on_completion (out x.1)).comap (stalk_to_valuation_field x)

end spa.presheaf