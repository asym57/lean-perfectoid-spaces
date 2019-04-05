import category_theory.instances.rings
import category_theory.full_subcategory
import category_theory.adjunction

import for_mathlib.uniform_space.ring

universe u

namespace category_theory

namespace instances

structure TopCommRing :=
(α : Type u)
(cr : comm_ring α)
(ts : topological_space α)
(tr : topological_ring α)

namespace TopCommRing

instance : has_coe_to_sort TopCommRing.{u} :=
{ S := Type u, coe := λ R, R.α }

section
variables (R S : TopCommRing.{u})

instance : comm_ring R := R.cr
instance : topological_space R := R.ts
instance : topological_ring R := R.tr

section uniform
local attribute [instance] topological_add_group.to_uniform_space
def uniform_space : uniform_space R := by apply_instance
def uniform_add_group : uniform_add_group R := topological_add_group_is_uniform
end uniform

end

instance : category TopCommRing.{u} :=
{ hom  := λ R S, {f : R → S // is_ring_hom f ∧ continuous f},
  id   := λ R, ⟨id, is_ring_hom.id, continuous_id⟩,
  comp := λ R S T f g,
    ⟨g.1 ∘ f.1, @@is_ring_hom.comp _ _ _ f.2.1 _ _ g.2.1, continuous.comp f.2.2 g.2.2⟩ }

section
variables (R S T : TopCommRing.{u})

instance : has_coe_to_fun (R ⟶ S) :=
{ F := λ f, R → S,
  coe := λ f, f.val }

@[simp] lemma id_val : subtype.val (𝟙 R) = (id : R → R) := rfl

variables {R S T} (f : R ⟶ S) (g : S ⟶ T)

@[simp] lemma comp_val : subtype.val (f ≫ g) = g ∘ f := rfl

instance : is_ring_hom f := f.2.1

lemma continuous : continuous f := f.2.2

section uniform
local attribute [instance] TopCommRing.uniform_space TopCommRing.uniform_add_group

lemma uniform_continuous : uniform_continuous f :=
uniform_continuous_of_continuous (continuous f)

end uniform

end

end TopCommRing

section uniform
local attribute [instance] topological_add_group.to_uniform_space

structure CmplTopCommRing extends TopCommRing.{u} :=
[cs : complete_space α]
[sp : separated α]

end uniform

namespace CmplTopCommRing

instance : category CmplTopCommRing.{u} := induced_category.category to_TopCommRing

instance : has_coe_to_sort CmplTopCommRing.{u} :=
{ S := Type u, coe := λ R, R.1 }

instance : has_coe CmplTopCommRing.{u} TopCommRing.{u} :=
⟨to_TopCommRing⟩

section
variables (R S T : CmplTopCommRing.{u})

section uniform
local attribute [instance] TopCommRing.uniform_space TopCommRing.uniform_add_group
instance : complete_space R := R.cs
instance : separated R := R.sp
end uniform

instance : has_coe_to_fun (R ⟶ S) :=
{ F := λ f, R → S,
  coe := λ f, f.val }

@[simp] lemma id_val : subtype.val (𝟙 R) = (id : R → R) := rfl

variables {R S T} (f : R ⟶ S) (g : S ⟶ T)

@[simp] lemma comp_val : subtype.val (f ≫ g) = g ∘ f := rfl

end

end CmplTopCommRing

namespace TopCommRing
section
open uniform_space

local attribute [instance] TopCommRing.uniform_space TopCommRing.uniform_add_group

noncomputable def completion : TopCommRing.{u} ⥤ CmplTopCommRing.{u} :=
{ obj := λ R,
  { α := ring_completion R,
    -- ideally all the following classes can be figured out automatically
    cr := sorry, ts := sorry, tr := sorry, cs := sorry, sp := sorry },
  map := λ R S f,
    ⟨ring_completion.map f.1,
      sorry, -- tried: ring_completion.map_is_ring_hom _ _ (TopCommRing.continuous f),
      -- so far getting errors...
      sorry⟩,
  -- map_comp' is not going to be solved by `tidy`, because
  -- uniform_continous is not a class.
  -- We have to invoke TopCommRing.uniform_continous manually
  -- until `back` lands in mathlib
  map_comp' := λ R S T f g, subtype.val_injective $
    by { erw ring_completion.map_comp, {refl}, all_goals {apply TopCommRing.uniform_continuous} } }

end

section
variables (R S : TopCommRing.{u})
local attribute [instance] TopCommRing.uniform_space TopCommRing.uniform_add_group

@[simp] lemma completion_obj_coe : (completion.obj R : Type u) = ring_completion R := rfl

def to_completion : R ⟶ completion.obj R :=
{ val := (coe : R → ring_completion R),
  property := sorry }

@[simp] lemma to_completion_val :
  (R.to_completion).val = (coe : R → ring_completion R) := rfl

variables {R S} (f : R ⟶ S)

@[simp] lemma completion_map_coe :
  (completion.map f : completion.obj R → completion.obj S) = ring_completion.map f := rfl

@[simp] lemma completion_map_val :
  subtype.val (completion.map f) = ring_completion.map f := rfl

noncomputable def completion.extension {S : CmplTopCommRing.{u}} (f : R ⟶ S) :
  completion.obj R ⟶ S :=
{ val := ring_completion.extension f,
  property := sorry }

end

noncomputable def completion_inclusion_adjunction :
  adjunction completion (induced_functor _) :=
{ hom_equiv := λ R S,
  { to_fun := λ f, R.to_completion ≫ f,
    inv_fun := λ g, sorry,
    left_inv := sorry,
    right_inv := sorry },
  unit :=
  { app := λ R, R.to_completion,
    naturality' := λ R S f, by { erw [subtype.ext], dsimp, sorry } },
  counit :=
  { app := λ S, completion.extension (𝟙 S),
    naturality' := λ R S f, by { erw [subtype.ext], dsimp, sorry } },
  hom_equiv_unit' := sorry,
  hom_equiv_counit' := sorry }


end TopCommRing

end instances

end category_theory
