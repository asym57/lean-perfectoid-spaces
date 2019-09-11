import topology.algebra.ordered

import for_mathlib.filter
import for_mathlib.topology

import valuation.linear_ordered_comm_group_with_zero

/-!
# The topology on linearly ordered commutative groups with zero

Let Γ be a linearly ordered commutative group to which we have adjoined a zero element.
Then Γ may naturally be endowed with a topology that turns Γ into a topological monoid.
The topology is the following:
A subset U ⊆ Γ is open if 0 ∉ U or if there is an invertible γ₀ ∈ Γ such that {γ | γ < γ₀} ⊆ U.

-/

local attribute [instance, priority 0] classical.decidable_linear_order

local notation `𝓝` x: 70 := nhds x

namespace linear_ordered_comm_group_with_zero
open topological_space filter set linear_ordered_structure
variables (Γ : Type*) [linear_ordered_comm_group_with_zero Γ]

/--The neighbourhoods around γ ∈ Γ, used in the definition of the topology on Γ.
These neighbourhoods are defined as follows:
A set s is a neighbourhood of 0 if there is an invertible γ₀ ∈ Γ such that {γ | γ < γ₀} ⊆ s.
If γ ≠ 0, then every set that contains γ is a neighbourhood of γ. -/
def nhds_fun : Γ → filter Γ :=
  (λ x : Γ, if x = 0 then ⨅ (γ₀ : units Γ), principal {γ | γ < γ₀} else pure x)

/--The topology on a linearly ordered commutative group with a zero element adjoined.
A subset U is open if 0 ∉ U or if there is an invertible element γ₀ such that {γ | γ < γ₀} ⊆ U. -/
protected def topological_space : topological_space Γ :=
topological_space.mk_of_nhds (nhds_fun Γ)

local attribute [instance] linear_ordered_comm_group_with_zero.topological_space

/--The neighbourhoods {γ | γ < γ₀} of 0 form a directed set indexed by the invertible elements γ₀.-/
lemma directed_lt : directed (≥) (λ (γ₀ : units Γ), principal {γ : Γ | γ < ↑γ₀}) :=
begin
  intros γ₁ γ₂,
  use min γ₁ γ₂,
  split,
  { change  principal {γ : Γ | γ < ↑(min γ₁ γ₂)} ≤ principal {γ : Γ | γ < ↑γ₁},
    rw [principal_mono, coe_min],
    intros x x_in,
    calc x < min ↑γ₁ ↑γ₂ : x_in
        ... ≤ γ₁ : min_le_left _ _ },
  { change  principal {γ : Γ | γ < ↑(min γ₁ γ₂)} ≤ principal {γ : Γ | γ < ↑γ₂},
    rw [principal_mono, coe_min],
    intros x x_in,
    calc x < min ↑γ₁ ↑γ₂ : x_in
        ... ≤ γ₂ : min_le_right _ _ }
end

-- We need two auxilliary lemmas to show that nhds_fun accurately describes the neighbourhoods
-- coming from the topology (that is defined in terms of nhds_fun).

/--At all points of a linearly ordered commutative group with a zero element adjoined,
the pure filter is smaller than the filter given by nhds_fun.-/
private lemma pure_le_nhds_fun : pure ≤ nhds_fun Γ :=
λ x, by { by_cases hx : x = 0; simp [hx, nhds_fun] }

/--For every point Γ, and every “neighbourhood” s of it (described by nhds_fun), there is a
smaller “neighbourhood” t ⊆ s, such that s is a “neighbourhood“ of all the points in t.-/
private lemma nhds_fun_ok : ∀ (x : Γ) (s ∈ nhds_fun Γ x),
  (∃ t ∈ nhds_fun Γ x, t ⊆ s ∧ ∀ y ∈ t, s ∈ nhds_fun Γ y) :=
begin
  intros x U U_in,
  by_cases hx : x = 0,
  { simp [hx, nhds_fun] at U_in ⊢,
    rw [mem_infi (directed_lt Γ) ⟨1⟩, mem_Union] at U_in,
    cases U_in with γ₀ h,
    use {γ : Γ | γ < ↑γ₀},
    rw mem_principal_sets at h,
    split,
    { apply mem_infi_sets γ₀,
      rw mem_principal_sets},
    { refine ⟨h, _⟩,
      intros y y_in,
      by_cases hy : y = 0 ; simp [hy, h y_in],
      { apply mem_infi_sets γ₀,
        rwa mem_principal_sets } } },
  { simp [hx, nhds_fun] at U_in ⊢,
    use {x},
    refine ⟨mem_singleton _, singleton_subset_iff.2 U_in, _⟩,
    intros y y_in,
    rw mem_singleton_iff at y_in,
    rw y_in,
    simpa [hx] }
end

variables  {Γ}
/--The neighbourhood filter of an invertible element consists of all sets containing that element.-/
@[simp] lemma nhds_coe (γ : units Γ) : 𝓝 (γ : Γ) = pure (γ : Γ) :=
calc 𝓝 (γ : Γ) = nhds_fun Γ γ : nhds_mk_of_nhds (nhds_fun Γ) γ (pure_le_nhds_fun Γ) (nhds_fun_ok Γ)
              ... = pure (γ : Γ) : if_neg (group_with_zero.unit_ne_zero γ)

/--The neighbourhood filter of a nonzero element consists of all sets containing that element.-/
@[simp] lemma nhds_of_ne_zero (γ : Γ) (h : γ ≠ 0) :
  𝓝 γ = pure γ :=
nhds_coe (group_with_zero.mk₀ _ h)

/--If γ is an invertible element of a linearly ordered group with zero element adjoined,
then {γ} is a neighbourhood of γ.-/
lemma singleton_nhds_of_units (γ : units Γ) : ({γ} : set Γ) ∈ 𝓝 (γ : Γ) :=
by simp

/--If γ is a nonzero element of a linearly ordered group with zero element adjoined,
then {γ} is a neighbourhood of γ.-/
lemma singleton_nhds_of_ne_zero (γ : Γ) (h : γ ≠ 0) : ({γ} : set Γ) ∈ 𝓝 (γ : Γ) :=
by simp [h]

/--If U is a neighbourhood of 0 in a linearly ordered group with zero element adjoined,
then there exists an invertible element γ₀ such that {γ | γ < γ₀} ⊆ U.
-/
lemma nhds_zero_mem (U : set Γ) : U ∈ 𝓝 (0 : Γ) ↔ ∃ γ₀ : units Γ, {γ : Γ | γ < γ₀} ⊆ U :=
begin
  rw nhds_mk_of_nhds (nhds_fun Γ) 0 (pure_le_nhds_fun Γ) (nhds_fun_ok Γ),
  simp [nhds_fun],
  rw mem_infi (directed_lt Γ) ⟨1⟩,
  { split,
    { rintro ⟨_, ⟨γ₀, rfl⟩, H⟩,
      rw mem_principal_sets at H,
      use [γ₀, H] },
    { rintro ⟨γ₀, H⟩,
      rw mem_Union,
      use γ₀,
      rwa mem_principal_sets } }
end

/--If γ is an invertible element of a linearly ordered group with zero element adjoined,
then {x | x < γ} is a neighbourhood of 0.-/
lemma nhds_zero_of_units (γ : units Γ) : {x : Γ | x < γ} ∈ 𝓝 (0 : Γ) :=
by { rw nhds_zero_mem, use γ }

/--If γ is a nonzero element of a linearly ordered group with zero element adjoined,
then {x | x < γ} is a neighbourhood of 0.-/
lemma nhds_zero_of_ne_zero (γ : Γ) (h : γ ≠ 0) : {x : Γ | x < γ} ∈ 𝓝 (0 : Γ) :=
nhds_zero_of_units (group_with_zero.mk₀ _ h)

variable (Γ)

/--The topology on a linearly ordered group with zero element adjoined
is compatible with the order structure.-/
def ordered_topology : ordered_topology Γ :=
{ is_closed_le' :=
  begin
    show is_open {p : Γ × Γ | ¬p.fst ≤ p.snd},
    simp only [not_le],
    rw is_open_iff_mem_nhds,
    rintros ⟨a,b⟩ hab,
    change b < a at hab,
    have ha : a ≠ 0 := ne_zero_of_gt hab,
    rw [nhds_prod_eq, mem_prod_iff],
    by_cases hb : b = 0,
    { subst b,
      use [{a}, singleton_nhds_of_ne_zero _ ha, {x : Γ | x < a}, nhds_zero_of_ne_zero _ ha],
      intros p p_in,
      cases mem_prod.1 p_in with h1 h2,
      rw mem_singleton_iff at h1,
      change p.2 < p.1,
      rwa h1 },
    { use [{a}, singleton_nhds_of_ne_zero _ ha, {b}, singleton_nhds_of_ne_zero _ hb],
      intros p p_in,
      cases mem_prod.1 p_in with h1 h2,
      rw mem_singleton_iff at h1 h2,
      change p.2 < p.1,
      rwa [h1, h2] }
  end }

local attribute [instance] ordered_topology

/--The topology on a linearly ordered group with zero element adjoined is T₂ (aka Hausdorff).-/
lemma t2_space : t2_space Γ := ordered_topology.to_t2_space

local attribute [instance] t2_space

/--The topology on a linearly ordered group with zero element adjoined is T₃ (aka regular).-/
lemma regular_space : regular_space Γ :=
begin
  haveI : t1_space Γ := t2_space.t1_space,
  split,
  intros s x s_closed x_not_in_s,
  by_cases hx : x = 0,
  { refine ⟨s, _, subset.refl _, _⟩,
    { subst x,
      rw is_open_iff_mem_nhds,
      intros y hy,
      by_cases hy' : y = 0, { subst y, contradiction },
      simpa [hy'] },
    { rw inf_eq_bot_iff,
      use -s,
      simp only [exists_prop, mem_principal_sets],
      split,
      exact mem_nhds_sets (by rwa is_open_compl_iff) (by rwa mem_compl_iff),
      exact ⟨s, subset.refl s, by simp⟩ } },
  { simp only [inf_eq_bot_iff, exists_prop, mem_principal_sets],
    exact ⟨-{x}, is_open_compl_iff.mpr is_closed_singleton, by rwa subset_compl_singleton_iff,
          {x}, singleton_nhds_of_ne_zero x hx, -{x}, by simp [subset.refl]⟩ }
end

/--The filter basis around the 0 element of a linearly ordered group with zero element adjoined.-/
def zero_filter_basis : filter_basis Γ :=
{ sets := range (λ γ : units Γ, {x : Γ | x < γ}),
  ne_empty := range_ne_empty.mpr ⟨1⟩,
  directed := begin
    intros s t hs ht,
    rw mem_range at hs ht,
    rcases hs with ⟨γs, rfl⟩,
    rcases ht with ⟨γt, rfl⟩,
    simp only [exists_prop, mem_range],
    rcases directed_lt Γ γs γt with ⟨γ, hs, ht⟩,
    change principal {g : Γ | g < ↑γ} ≤ principal {g : Γ | g < ↑γt} at ht,
    change principal {g : Γ | g < ↑γ} ≤ principal {g : Γ | g < ↑γs} at hs,
    rw [le_principal_iff, mem_principal_sets] at hs ht,
    use [{x : Γ | x < γ}, γ, rfl, subset_inter_iff.mpr ⟨hs, ht⟩]
  end}

variable {Γ}

/--The filter basis around nonzero elements of
a linearly ordered group with zero element adjoined.-/
def ne_zero_filter_basis (x : Γ) (h : x ≠ 0) : filter_basis Γ :=
{ sets := ({({x} : set Γ)} : set (set Γ)),
  ne_empty := by simp,
  directed := by finish }

variable (Γ)

/--The neighbourhood basis of a linearly ordered group with zero element adjoined.-/
def nhds_basis : nhds_basis Γ :=
{ B := λ x, if h : x = 0 then zero_filter_basis Γ else ne_zero_filter_basis x h,
  is_nhds := begin
    intro x,
    ext s,
    split_ifs with hx,
    { subst x,
      rw nhds_zero_mem,
      simp [zero_filter_basis, filter_basis.mem_filter, filter_basis.mem_iff],
      split,
      { rintros ⟨γ₀, h⟩,
        use [{x : Γ | x < ↑γ₀}, γ₀, h] },
      { rintros ⟨_, ⟨γ₀, rfl⟩, h⟩,
        exact ⟨γ₀, h⟩ } },
    { simp [hx, filter_basis.mem_filter, filter_basis.mem_iff, ne_zero_filter_basis], }
  end }

local attribute [instance] nhds_basis

lemma mem_nhds_basis_zero {U : set Γ} :
  U ∈ nhds_basis.B (0 : Γ) ↔ ∃ γ : units Γ, U = {x : Γ | x < γ } :=
begin
  dsimp [nhds_basis, zero_filter_basis],
  simp only [dif_pos],
  convert iff.rfl,
  simp [eq_comm]
end

lemma mem_nhds_basis_ne_zero {U : set Γ} {γ₀ : Γ} (h : γ₀ ≠ 0) :
  U ∈ nhds_basis.B γ₀ ↔ U = {γ₀} :=
begin
  dsimp [nhds_basis],
  simp only [dif_neg h],
  dsimp [filter_basis.has_mem, ne_zero_filter_basis γ₀ h],
  exact set.mem_singleton_iff
end

variable {Γ}

-- until the end of this section, all linearly ordered commutative groups will be endowed with
-- the discrete topology
variables (α : Type*) [linear_ordered_comm_group α]
def discrete_ordered_comm_group : topological_space α := ⊥

local attribute [instance] discrete_ordered_comm_group
def ordered_comm_group_is_discrete : discrete_topology α := ⟨rfl⟩
local attribute [instance] ordered_comm_group_is_discrete

lemma comap_coe_nhds (γ : units Γ) : 𝓝 γ = comap coe (𝓝 (γ : Γ)) :=
begin
  rw [nhds_discrete, filter.comap_pure (λ _ _ h, units.ext h) γ],
  change comap coe (pure (γ : Γ)) = comap coe (𝓝 ↑γ),
  rw ← nhds_coe γ,
end

lemma tendsto_zero {α : Type*} {F : filter α} {f : α → Γ} :
  tendsto f F (𝓝 (0 : Γ)) ↔ ∀ γ₀ : units Γ, { x : α | f x < γ₀ } ∈ F :=
begin
  rw nhds_basis.tendsto_into,
  simp only [mem_nhds_basis_zero, exists_imp_distrib],
  split ; intro h,
  { intro γ₀,
    exact h {γ | γ < ↑γ₀} γ₀ rfl },
  { rintros _ γ₀ rfl,
    exact h γ₀ }
end

lemma mem_nhds_zero {s} :
  s ∈ 𝓝 (0 : Γ) ↔ ∃ γ : units Γ, { x : Γ | x < γ } ⊆ s :=
begin
  rw nhds_basis.mem_nhds_iff,
  simp only [exists_prop, mem_nhds_basis_zero],
  split,
  { rintros ⟨_, ⟨⟨γ, rfl⟩, h⟩⟩,
    exact ⟨γ, h⟩ },
  { rintros ⟨γ, h⟩,
    exact ⟨{x : Γ | x < γ}, ⟨γ, rfl⟩, h⟩ }
end

lemma mem_nhds_coe {s} {γ : Γ} (h : γ ≠ 0) :
  s ∈ 𝓝 γ ↔ γ ∈ s :=
begin
  rw nhds_basis.mem_nhds_iff,
  simp only [exists_prop, mem_nhds_basis_ne_zero _ h, h],
  split,
  { rintros ⟨_, rfl, h₂⟩,
    rwa singleton_subset_iff at h₂ },
  { intro h,
    use [{γ}, rfl],
    rwa singleton_subset_iff },
end

lemma tendsto_nonzero {α : Type*} {F : filter α} {f : α → Γ} {γ₀ : Γ} (h : γ₀ ≠ 0) :
  tendsto f F (𝓝 (γ₀ : Γ)) ↔ { x : α | f x = γ₀ } ∈ F :=
begin
  rw nhds_basis.tendsto_into,
  simp only [mem_nhds_basis_ne_zero _ h, forall_eq],
  convert iff.rfl,
  ext s,
  exact mem_singleton_iff.symm
end

instance : topological_monoid Γ :=
⟨begin
  rw continuous_iff_continuous_at,
  rintros ⟨x, y⟩,
  by_cases hx : x = 0; by_cases hy : y = 0,
  all_goals {
    try {subst x}, try {subst y},
    intros U U_in,
    rw nhds_prod_eq,
    try { simp only [_root_.mul_zero, _root_.zero_mul] at U_in},
    rw mem_nhds_zero at U_in <|> rw [mem_nhds_coe] at U_in,
    rw mem_map,
    rw mem_prod_same_iff <|> rw mem_prod_iff,
    try { cases U_in with γ hγ } },
  { cases linear_ordered_structure.exists_square_le γ with γ₀ hγ₀,
    simp only [mem_nhds_zero, exists_prop],
    use [{x : Γ | x < ↑γ₀}, γ₀, subset.refl _, {x : Γ | x < ↑γ₀}, γ₀, subset.refl _],
    rw set.prod_subset_iff,
    intros x x_in y y_in,
    apply hγ,
    change x*y < γ,
    have := mul_lt_mul' x_in y_in,
    refine lt_of_lt_of_le this _,
    exact_mod_cast hγ₀ },
  { simp only [set.prod_subset_iff, mem_nhds_zero, mem_nhds_coe hy, exists_prop],
    use [{x : Γ | x < γ*y⁻¹}, γ * (group_with_zero.mk₀ y hy)⁻¹, subset.refl _,
      {(group_with_zero.mk₀ y hy)}, mem_singleton y],
    intros x x_in y' y'_in,
    rw mem_singleton_iff at y'_in,
    rw y'_in,
    apply hγ,
    change x * y < γ,
    simpa [hy] using mul_lt_right' y x_in hy, },
  { simp only [set.prod_subset_iff, mem_nhds_zero, mem_nhds_coe hx, exists_prop],
    use [{(group_with_zero.mk₀ x hx)}, mem_singleton _, {y : Γ | y < γ*x⁻¹},
      γ * (group_with_zero.mk₀ x hx)⁻¹, subset.refl _],
    intros x' x'_in y y_in,
    rw mem_singleton_iff at x'_in,
    rw x'_in,
    apply hγ,
    change x * y < γ,
    rw mul_comm,
    simpa [hx] using mul_lt_right' x y_in hx, },
  { simp [mem_nhds_coe, hx, hy],
    use [{x}, mem_singleton _, {y}, mem_singleton _],
    rw set.prod_subset_iff,
    intros x' x'_in y' y'_in,
    rw mem_singleton_iff at *,
    rw [x'_in, y'_in],
    simpa using U_in },
  { assume H, simp at H, tauto }
end⟩

end linear_ordered_comm_group_with_zero
