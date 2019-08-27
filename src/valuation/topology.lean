/-
In this file, we define the topology induced by a valuation on a ring

valuation.topology {Γ : Type*} [linear_ordered_comm_group Γ] {R : Type*} [ring R] :
    valuation R Γ → topological_space R
-/
import for_mathlib.nonarchimedean.is_subgroups_basis
import for_mathlib.uniform_space.group_basis
import valuation.basic

local attribute [instance] classical.prop_decidable
noncomputable theory

local attribute [instance, priority 0] classical.decidable_linear_order

open set valuation with_zero

local notation `𝓝` x: 70 := nhds x

section
variables {Γ : Type*} [linear_ordered_comm_group Γ]
variables {R : Type*} [ring R]

def valuation.subgroup (v : valuation R Γ) (γ : Γ) : set R := {x | v x < γ}

lemma valuation.lt_is_add_subgroup (v : valuation R Γ) (γ : Γ) : is_add_subgroup {x | v x < γ} :=
{ zero_mem := by simp only [valuation.map_zero, mem_set_of_eq] ; apply with_zero.zero_lt_coe,
  add_mem := λ x y x_in y_in, lt_of_le_of_lt (map_add_le_max v x y) (max_lt x_in y_in),
  neg_mem := λ x x_in, by rwa [mem_set_of_eq, map_neg] }

-- is this an OK place to put this?
lemma valuation.le_is_add_subgroup (v : valuation R Γ) (γ : Γ): is_add_subgroup {x | v x ≤ γ} :=
{ zero_mem := by simp only [valuation.map_zero, mem_set_of_eq]; apply le_of_lt (with_zero.zero_lt_coe),
  add_mem := λ x y x_in y_in, le_trans (map_add_le_max v x y) (max_le x_in y_in),
  neg_mem := λ x x_in, by rwa [mem_set_of_eq, map_neg] }

end

local attribute [instance] valuation.lt_is_add_subgroup

universe u

class valued (R : Type u) [ring R] :=
(Γ : Type u)
[grp : linear_ordered_comm_group Γ]
(v : valuation R Γ)

attribute [instance] valued.grp

open valued

namespace valued
variables {R : Type*} [ring R] [valued R]

def value : R → with_zero (valued.Γ R) := λ x, (valued.v R).val x

local notation `v` := valued.value
local notation `Γ₀` R := with_zero (Γ R)

-- The following four lemmas are restatements that seem to be unfortunately needed

lemma map_zero : v (0 : R) = 0 :=
begin
  change valued.v R (0 : R) = 0,
  apply valuation.map_zero
end

lemma map_one : v (1 : R) = 1 :=
begin
  change valued.v R _ = _,
  apply valuation.map_one
end

lemma map_mul (x y : R) : v (x*y) = v x * v y :=
begin
  change valued.v R _ = _,
  apply valuation.map_mul
end

lemma map_add (x y : R) : v (x+y) ≤ v x ∨ v (x+y) ≤ v y :=
begin
  change valued.v R _ ≤ _ ∨ valued.v R _ ≤ _,
  apply valuation.map_add
end

def subgroups_basis : subgroups_basis R :=
{ sets := range (valued.v R).subgroup,
  ne_empty := ne_empty_of_mem (mem_range_self 1),
  directed := begin
    rintros _ _ ⟨γ₀, rfl⟩ ⟨γ₁, rfl⟩,
    rw exists_mem_range,
    use min γ₀ γ₁,
    simp only [set_of_subset_set_of, subset_inter_iff, valuation.subgroup],
    split ; intros x x_lt ;  rw coe_min at x_lt,
    { exact lt_of_lt_of_le x_lt (min_le_left _ _) },
    { exact lt_of_lt_of_le x_lt (min_le_right _ _) }
  end,
  sub_groups := by { rintros _ ⟨γ, rfl⟩, exact (valued.v R).lt_is_add_subgroup γ },
  h_mul := begin
    rintros _ ⟨γ, rfl⟩,
    rw set.exists_mem_range',
    cases linear_ordered_structure.exists_square_le γ with γ₀ h,
    replace h : (γ₀*γ₀ : with_zero $ valued.Γ R) ≤ γ, exact_mod_cast h,
    use γ₀,
    rintro x ⟨r, r_in, s, s_in, rfl⟩,
    refine lt_of_lt_of_le _ h,
    rw valuation.map_mul,
    exact with_zero.mul_lt_mul r_in s_in
  end,
  h_left_mul := begin
      rintros x _ ⟨γ, rfl⟩,
      rw exists_mem_range',
     dsimp [valuation.subgroup],
      by_cases Hx : ∃ γx : Γ R, v x = (γx : Γ₀ R),
      { cases Hx with γx Hx,
        simp only [image_subset_iff, set_of_subset_set_of, preimage_set_of_eq, valuation.map_mul],
        use γx⁻¹*γ,
        intros y vy_lt,
        change  v y < ↑(γx⁻¹ * γ) at vy_lt,
        change v x * v y < ↑γ,
        rw Hx,
        rw ← with_zero.mul_coe at vy_lt,
        apply actual_ordered_comm_monoid.lt_of_mul_lt_mul_left (γx⁻¹ : Γ₀ R),
        rwa [← mul_assoc, with_zero.mul_left_inv _ (coe_ne_zero), one_mul, inv_coe] },
      { rw [← ne_zero_iff_exists, not_not] at Hx,
        use 1,
        intros y y_in,
        erw [mem_set_of_eq, valuation.map_mul],
        change v x * v y < _,
        erw [Hx, zero_mul],
        exact zero_lt_coe }
  end,
  h_right_mul := begin
    rintros x _ ⟨γ, rfl⟩,
    rw exists_mem_range',
    dsimp [valuation.subgroup],
    by_cases Hx : ∃ γx : Γ R, v x = γx,
    { cases Hx with γx Hx,
      simp only [image_subset_iff, set_of_subset_set_of, preimage_set_of_eq, valuation.map_mul],
      use γ * γx⁻¹,
      intros y vy_lt,
      change v y * v x < _,
      rw Hx,
      apply actual_ordered_comm_monoid.lt_of_mul_lt_mul_right' (γx⁻¹ : Γ₀ R),
      rwa [mul_assoc, with_zero.mul_right_inv _ (coe_ne_zero), mul_one, inv_coe], },
    { rw [← ne_zero_iff_exists, not_not] at Hx,
      use 1,
      intros y y_in,
      rw [mem_set_of_eq, valuation.map_mul],
      change v y * v x < _,
      erw [Hx, mul_zero],
      exact zero_lt_coe }
  end }

local attribute [instance] valued.subgroups_basis subgroups_basis.topology ring_filter_basis.topological_ring

lemma mem_basis_zero [valued R] {s : set R} :
  s ∈ filter_basis.sets R ↔ ∃ γ : valued.Γ R, {x | valued.v R x < (γ : with_zero $ valued.Γ R)} = s :=
iff.rfl


lemma mem_nhds [valued R] {s : set R} {x : R} :
  (s ∈ 𝓝 x) ↔ ∃ γ : valued.Γ R, {y | v (y - x) < γ } ⊆ s :=
begin
  erw [subgroups_basis.mem_nhds, exists_mem_range],
  exact iff.rfl,
end

lemma mem_nhds_zero [valued R] {s : set R} :
  (s ∈ 𝓝 (0 : R)) ↔ ∃ γ : Γ R, {x | v x < (γ : Γ₀ R) } ⊆ s :=
by simp [valued.mem_nhds, sub_zero]

lemma loc_const [valued R] {x : R} (h : v x ≠ 0) : {y : R | v y = v x} ∈ 𝓝 x :=
begin
  rw valued.mem_nhds,
  rcases with_zero.ne_zero_iff_exists.mp h with ⟨γ, hx⟩,
  use γ,
  rw ← hx,
  intros y y_in,
  exact valuation.map_eq_of_sub_lt _ y_in
end

def uniform_space [valued R] : uniform_space R :=
topological_add_group.to_uniform_space R

local attribute [instance] valued.uniform_space

lemma uniform_add_group [valued R] : uniform_add_group R :=
topological_add_group_is_uniform

local attribute [instance] valued.uniform_add_group

lemma cauchy_iff [valued R] {F : filter R} :
  cauchy F ↔ F ≠ ⊥ ∧ ∀ γ : valued.Γ R, ∃ M ∈ F,
    ∀ x y, x ∈ M → y ∈ M → y - x ∈ {x : R | valued.v R x < ↑γ} :=
begin
    rw add_group_filter_basis.cauchy_iff R rfl,
    apply and_congr iff.rfl,
    split,
    { intros h γ,
      apply h,
      erw valued.mem_basis_zero,
      use γ },
    { intros h U U_in,
      rcases valued.mem_basis_zero.mp U_in with ⟨γ, rfl⟩, clear U_in,
      apply h }
end
end valued
