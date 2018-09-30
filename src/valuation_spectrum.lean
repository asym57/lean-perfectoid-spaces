import valuations 
import analysis.topology.topological_space
import data.finsupp
import group_theory.quotient_group
import valuation_universe 

universes u₁ u₂ u₃

open valuation quotient_group

definition Spv (R : Type u₁) [comm_ring R] := 
{ineq : R → R → Prop // ∃ (Γ : Type u₁) [linear_ordered_comm_group Γ],
  by exactI ∃ (v : valuation R Γ), ∀ r s : R, ineq r s ↔ v r ≤ v s}

namespace Spv 

set_option class.instance_max_depth 41

-- decidable equality on R to make the finsupp an add_comm_group?!

/-
theorem value_group_universe (R : Type u₁) [comm_ring R] [decidable_eq R] (Γ₂ : Type u2) [linear_ordered_comm_group Γ₂]
  (v₂ : R → option Γ₂) (Hv₂ : is_valuation v₂) : 
∃ (Γ₁ : Type u₁) [linear_ordered_comm_group Γ₁], by exactI ∃ (v₁ : R → option Γ₁) (Hv₁ : is_valuation v₁),
  (∀ r s : R, v₁ r ≤ v₁ s ↔ v₂ r ≤ v₂ s) ∧ value_group_f v₁ = set.univ := 
-/
variables {R : Type u₁} [comm_ring R] [decidable_eq R] 
variables (Γ₂ : Type u₂) [linear_ordered_comm_group Γ₂]
variables (v₂ : valuation R  Γ₂)
include Γ₂

structure parametrized_subgroup :=
(Γ : Type u₁)
[grp : comm_group Γ]
(map : Γ → Γ₂)
(hom : is_group_hom map)
(inj : function.injective map)

local attribute [instance] parametrized_subgroup.grp
local attribute [instance] parametrized_subgroup.hom

variable {Γ₂}
include R v₂ 

def minimal_value_group : parametrized_subgroup Γ₂ :=
begin
  let FG : Type u₁ := multiplicative (R →₀ ℤ), -- free ab group on R
  let φ₀ : R → Γ₂ := λ r, option.get_or_else (v₂ r) 1,
  let φ : FG → Γ₂ := λ f, finsupp.prod f (λ r n,(φ₀ r) ^ n),
  haveI : is_group_hom φ := 
    ⟨λ a b, finsupp.prod_add_index (λ a, rfl) (λ a b₁ b₂, gpow_add (φ₀ a) b₁ b₂)⟩,
  
  exact
  { Γ :=  quotient (is_group_hom.ker φ),
    map   :=  lift (is_group_hom.ker φ) φ (λ _,(is_group_hom.mem_ker φ).1),
    hom   := quotient_group.is_group_hom_quotient_lift _ _ _,
    inj   := injective_ker_lift φ }
end

def minimal_value_group.mk (r : R) : (minimal_value_group v₂).Γ :=
begin
  let FG : Type u₁ := multiplicative (R →₀ ℤ), -- free ab group on R
  let φ₀ : R → Γ₂ := λ r, option.get_or_else (v₂ r) 1,
  let φ : FG → Γ₂ := λ f, finsupp.prod f (λ r n,(φ₀ r) ^ n),
  haveI : is_group_hom φ := 
    ⟨λ a b, finsupp.prod_add_index (λ a, rfl) (λ a b₁ b₂, gpow_add (φ₀ a) b₁ b₂)⟩,

 exact quotient_group.mk (finsupp.single r (1 : ℤ))
end

lemma minimal_value_group.mk_some {r : R} {g : Γ₂} (h : v₂ r = some g) : 
  v₂ r = some ((minimal_value_group v₂).map (minimal_value_group.mk v₂ r)) :=
begin
  rw h,
  congr' 1,
  dsimp[minimal_value_group, minimal_value_group.mk],
  rw finsupp.prod_single_index ; finish
end

instance valuation.minimal_value_group_is_linear_ordered_comm_group : 
linear_ordered_comm_group (minimal_value_group v₂).Γ :=
begin
  cases minimal_value_group v₂ with Γ₁ _ ψ _ inj,
  
  letI Γ₁linord : linear_order Γ₁ := 
  { le := λ g h,ψ g ≤ ψ h,
    le_refl := λ _,le_refl _,
    le_trans := λ _ _ _ hab hbc,le_trans hab hbc,
    le_antisymm := λ g h Hgh Hhg, inj $ le_antisymm Hgh Hhg,
    le_total := λ g h, le_total _ _ },
  exact ⟨λ a b H c,
    begin 
      change ψ (c * a) ≤ ψ (c * b),
      rw [is_group_hom.mul ψ c b, is_group_hom.mul ψ c a],
      exact linear_ordered_comm_group.mul_le_mul_left H _,
    end⟩
end

definition valuation.minimal_valuation (r : R) : with_zero ((minimal_value_group v₂).Γ) :=
match v₂ r with 
| some _ := some (minimal_value_group.mk v₂ r)
| 0 := 0
end

lemma valuation.minimal_valuation_none {r : R} (h : v₂ r = 0) : valuation.minimal_valuation v₂ r = 0 :=
by simp [valuation.minimal_valuation, h]

lemma valuation.minimal_valuation_some {r : R} {g} (h : v₂ r = some g) :
  valuation.minimal_valuation v₂ r = some (minimal_value_group.mk v₂ r) :=
by simp[valuation.minimal_valuation, h]

lemma valuation.minimal_valuation_map (r : R) :
  option.map (minimal_value_group v₂).map (valuation.minimal_valuation v₂ r) = v₂ r :=
begin
  destruct (v₂ r),
  { intro h, 
    simp[valuation.minimal_valuation_none v₂ h, h] },
  { intros g h,
    rw [minimal_value_group.mk_some v₂ h, valuation.minimal_valuation_some v₂ h, option.map_some'] },
end

instance valuation.minimal_valuation_is_valuation : is_valuation (valuation.minimal_valuation v₂) :=
let v₁ := valuation.minimal_valuation v₂ in let Γ₁ := minimal_value_group v₂ in
  valuation.valuation_of_valuation R v₁ v₂ Γ₁.map
    Γ₁.inj (valuation.minimal_valuation_map v₂) (λ g h,iff.refl _) (by apply_instance)

definition valuation.minimal_valuation_equiv (r s : R) :
  valuation.minimal_valuation v₂ r ≤ valuation.minimal_valuation v₂ s ↔ v₂ r ≤ v₂ s :=
valuation.le_of_le _ _ _ _ (valuation.minimal_valuation_map v₂) (λ g h, iff.refl _) r s


definition quot.mk : Spv R := ⟨λ r s, v₂ r ≤ v₂ s,
  begin
    let Γ₁ := (minimal_value_group v₂).Γ,
    let v₁ := valuation.minimal_valuation v₂,
    let v : valuation R Γ₁ := { f := v₁, ..(valuation.minimal_valuation_is_valuation v₂) },
    existsi [Γ₁, valuation.minimal_value_group_is_linear_ordered_comm_group v₂, v],
    intros r s,
    show _ ↔ v₁ r ≤ v₁ s,
    rw valuation.minimal_valuation_equiv v₂ r s,
  end⟩

definition mk (v : valuation R Γ₂) : Spv R := quot.mk v.f

end Spv 

-- TODO:

-- quot.lift takes a function defined on valuation functions and produces a function defined on Spv
-- quot.ind as well
--or equivalently quot.exists_rep
-- exists_rep {α : Sort u} {r : α → α → Prop} (q : quot r) : ∃ a : α, (quot.mk r a) = q :=
-- that is, for every element of Spv there is a valuation function that quot.mk's to it
-- Note it's not actually a function producing valuation functions, it's an exists
-- if you prove analogues of those theorems for your type, then you have constructed the
--  quotient up to isomorphism
-- This all has a category theoretic interpretation as a coequalizer, and all constructions
--  are natural in that category
-- As opposed to, say, quot.out, which picks an element from an equivalence class
-- Although in your case if I understand correctly you also have a canonical way to define quot.out
--  satisfying some other universal property to do with the ordered group

-- **also need to check that continuity is well-defined on Spv R**
-- continuity of an inequality is defined using the minimal Gamma
-- need value_group_f v₁ = set.univ

-- Also might need a variant of  Wedhorn 1.27 (ii) -/

/-
theorem equiv_value_group_map (R : Type) [comm_ring R] (v w : valuations R) (H : v ≈ w) :
∃ φ : value_group v.f → value_group w.f, is_group_hom φ ∧ function.bijective φ :=
begin
  existsi _,tactic.swap,
  { intro g,
    cases g with g Hg,
    unfold value_group at Hg,
    unfold group.closure at Hg,
    dsimp at Hg,
    induction Hg,
  },
  {sorry 

  }
end 
-/

namespace Spv 

variables {A : Type*} [comm_ring A]

definition basic_open (r s : A) : set (Spv A) := 
{v | v.val r s ∧ ¬ v.val s 0}

instance (A : Type*) [comm_ring A] : topological_space (Spv A) :=
topological_space.generate_from {U : set (Spv A) | ∃ r s : A, U = basic_open r s}

end Spv 