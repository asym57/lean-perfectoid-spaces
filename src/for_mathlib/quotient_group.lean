import group_theory.coset

universes u v 

variables {G : Type u} [group G] (N : set G) [normal_subgroup N] {H : Type v} [group H]

namespace group 

local attribute [instance] left_rel normal_subgroup.to_is_subgroup

definition quotient_group := left_cosets N 

local notation ` Q ` := quotient_group N

instance : group Q := left_cosets.group N 

instance quotient.inhabited : inhabited Q := ⟨1⟩

definition quotient.mk : G → Q := λ g, ⟦g⟧

instance is_group_hom_quotient_mk : is_group_hom (quotient.mk N) := by refine {..}; intros; refl 

def quotient.lift (φ : G → H) [Hφ : is_group_hom φ] (HN : ∀x∈N, φ x = 1) (q : Q) : H :=
q.lift_on φ $ assume a b (hab : a⁻¹ * b ∈ N),
(calc φ a = φ a * 1 : by rw mul_one
...       = φ a * φ (a⁻¹ * b) : by rw HN (a⁻¹ * b) hab
...       = φ (a * (a⁻¹ * b)) : by rw is_group_hom.mul φ a (a⁻¹ * b)
...       = φ ((a * a⁻¹) * b) : by rw mul_assoc;refl
...       = φ (1 * b)         : by rw mul_inv_self
...       = φ b               : by rw one_mul)

@[simp] lemma quotient.lift_mk {φ : G → H} [Hφ : is_group_hom φ] (HN : ∀x∈N, φ x = 1) (g : G) :
  quotient.lift N φ HN ⟦g⟧ = φ g := by refl

@[simp] lemma quotient.lift_mk' {φ : G → H} [Hφ : is_group_hom φ] (HN : ∀x∈N, φ x = 1) (g : G) :
  quotient.lift N φ HN (group.quotient.mk N g) = φ g := by refl


instance is_group_hom_quotient_lift (φ : G → H) [Hφ : is_group_hom φ] (HN : ∀x∈N, φ x = 1) :
  is_group_hom (group.quotient.lift N φ HN) := 
⟨λ q r, quotient.induction_on₂ q r $ λ a b, show φ (a * b) = φ a * φ b, from is_group_hom.mul φ a b⟩

--lemma is_group_hom_quotient_lift (φ : G → H) {HN : ∀x y, x⁻¹ * y ∈ N → φ x = φ y}
--[Hφ : is_group_hom φ] : is_group_hom (λ q : Q, quotient.lift_on q φ HN) := 
--⟨λ q r, quotient.induction_on₂ q r $ λ a b, show φ (a * b) = φ a * φ b, from is_group_hom.mul φ a b⟩

open function 

lemma quotient.injective_lift (φ : G → H) [Hφ : is_group_hom φ]
  (HN : N = {x | φ x = 1}) : injective 
--  (quotient.lift N φ $ λ x h,by rwa HN at h) 
  (group.quotient.lift N φ $ λ x h, by rwa HN at h)
  :=
assume a b, quotient.induction_on₂ a b $ assume a b (h : φ a = φ b), quotient.sound $ 
have φ (a⁻¹ * b) = 1, by rw [Hφ.mul,←h,is_group_hom.inv φ,inv_mul_self],
show a⁻¹ * b ∈ N,from HN.symm ▸ this

variables {cG : Type u} [comm_group cG] (cN : set cG) [normal_subgroup cN] 

instance : comm_group (group.quotient_group cN) := 
{ mul_comm := λ a b,quotient.induction_on₂ a b $ λ g h, 
    show ⟦g * h⟧ = ⟦h * g⟧, 
    by rw [mul_comm g h],
  ..left_cosets.group cN
}

end group

