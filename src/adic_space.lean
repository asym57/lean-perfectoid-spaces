import algebra.group_power
import topology.algebra.ring
import topology.opens
import category_theory.category
import category_theory.full_subcategory

import for_mathlib.sheaves.sheaf_of_topological_rings
import for_mathlib.open_embeddings
import for_mathlib.topological_groups

import continuous_valuations
import r_o_d_completion stalk_valuation
import Huber_pair

/-!
# Adic spaces

Adic spaces were introduced by Huber in [Huber]. They form a very general category of objects
suitable for p-adic geometry.

In this file we define the category of adic spaces. The category of schemes (from algebraic
geometry) may provide some useful intuition for the definition.
One defines the category of “ringed spaces”, and for every commutative ring R
a ringed space Spec(R). A scheme is a ringed space that admits a cover by subspaces that
are isomorphic to spaces of the form Spec(R) for some ring R.

Similarly, for adic spaces we need two ingredients: a category CLVRS,
and the so-called ”adic spectrum” Spa(_), which is defined in Spa.lean.
An adic space is an object of CLVRS is that admits a cover by subspaces of the form Spa(A).

The main bulk of this file consists in setting up the category that we called CLVRS,
and that never got a proper name in the literature. (For example, Wedhorn calls this category `𝒱`.)

CLVRS (complete locally valued ringed space) is the category of topological spaces endowed
with a sheaf of complete topological rings and (an equivalence class of) valuations on the stalks
(which are required to be local rings; moreover the support of the valuation must be
the maximal ideal of the stalk).

Once we have the category CLVRS in place, the definition of adic spaces is made in
a couple of lines.
-/

universe u

open nat function
open topological_space
open spa

namespace sheaf_of_topological_rings

-- Maybe we could make this an instance?
def uniform_space {X : Type u} [topological_space X] (𝒪X : sheaf_of_topological_rings X)
  (U : opens X) : uniform_space (𝒪X.F.F U) :=
topological_add_group.to_uniform_space (𝒪X.F.F U)

end sheaf_of_topological_rings

/-- A convenient auxiliary category whose objects are topological spaces equipped with
a presheaf of topological rings and on each stalk (considered as abstract ring) an
equivalence class of valuations. The point of this category is that the local isomorphism
between a general adic space and an affinoid model Spa(A) can be checked in this category.
-/
structure PreValuedRingedSpace :=
(space : Type u)
(top   : topological_space space)
(presheaf : presheaf_of_topological_rings.{u u} space)
(valuation : ∀ x : space, Spv (stalk_of_rings presheaf.to_presheaf_of_rings x))

namespace PreValuedRingedSpace

variables (X : PreValuedRingedSpace.{u})

/-- Coercion from a PreValuedRingedSpace to the underlying topological space-/
instance : has_coe_to_sort PreValuedRingedSpace.{u} :=
{ S := Type u,
  coe := λ X, X.space }

-- Adding the fact that the underlying space of a PreValuedRingedSpace is a topological
-- space, to the type class inference system
instance : topological_space X := X.top

end PreValuedRingedSpace

/- Remainder of this file:

* Morphisms and isomorphisms in PreValuedRingedSpace.
* Open set in X -> restrict structure to obtain object of PreValuedRingedSpace
* Definition of adic space

* A morphism in PreValuedRingedSpace is a map of topological spaces,
  and an f-map of presheaves, such that the induced
  map on the stalks pulls one valuation back to the other.
-/

structure presheaf_of_rings.f_map
  {X : Type u} [topological_space X] {Y : Type u} [topological_space Y]
  (F : presheaf_of_rings X) (G : presheaf_of_rings Y) :=
(f : X → Y)
(hf : continuous f)
(f_flat : ∀ V : opens Y, G V → F (hf.comap V))
(f_flat_is_ring_hom : ∀ V : opens Y, is_ring_hom (f_flat V))
(presheaf_f_flat : ∀ V W : opens Y, ∀ (hWV : W ⊆ V),
  ∀ s : G V, F.res _ _ (hf.comap_mono hWV) (f_flat V s) = f_flat W (G.res V W hWV s))

instance presheaf_of_rings.f_map_flat_is_ring_hom
  {X : Type u} [topological_space X] {Y : Type u} [topological_space Y]
  {F : presheaf_of_rings X} {G : presheaf_of_rings Y}
  (f : presheaf_of_rings.f_map F G) (V : opens Y) :
  is_ring_hom (f.f_flat V) := f.f_flat_is_ring_hom V

def presheaf_of_rings.f_map_id {X : Type u} [topological_space X]
  (F : presheaf_of_rings X) : presheaf_of_rings.f_map F F :=
{ f := λ x, x,
  hf := continuous_id,
  f_flat := λ U, F.res _ _ (λ _ hx, hx),
  f_flat_is_ring_hom := λ U, begin
      convert is_ring_hom.id,
      { simp [continuous.comap_id U] },
      { simp [continuous.comap_id U] },
      { simp [continuous.comap_id U] },
      convert heq_of_eq (F.Hid U),
      swap, exact continuous.comap_id U,
      rw continuous.comap_id U,
      refl,
    end,
  presheaf_f_flat :=  λ U V hVU s, begin
      rw ←F.to_presheaf.Hcomp',
      rw ←F.to_presheaf.Hcomp',
    end }

def presheaf_of_rings.f_map_comp
  {X : Type u} [topological_space X] {Y : Type u} [topological_space Y] {Z : Type u} [topological_space Z]
  {F : presheaf_of_rings X} {G : presheaf_of_rings Y} {H : presheaf_of_rings Z}
  (a : presheaf_of_rings.f_map F G) (b : presheaf_of_rings.f_map G H) : presheaf_of_rings.f_map F H :=
{ f := λ x, b.f (a.f x),
  hf := b.hf.comp a.hf,
  f_flat := λ V s, (a.f_flat (b.hf.comap V)) ((b.f_flat V) s),
  f_flat_is_ring_hom := λ V, show (is_ring_hom ((a.f_flat (b.hf.comap V)) ∘ (b.f_flat V))), from is_ring_hom.comp _ _,
  presheaf_f_flat := λ V W hWV s, begin
    rw ←b.presheaf_f_flat V W hWV s,
    rw ←a.presheaf_f_flat (b.hf.comap V) (b.hf.comap W) (b.hf.comap_mono hWV),
    refl,
  end }

structure presheaf_of_topological_rings.f_map
  {X : Type u} [topological_space X] {Y : Type u} [topological_space Y]
  (F : presheaf_of_topological_rings X) (G : presheaf_of_topological_rings Y) :=
(f : X → Y)
(hf : continuous f)
(f_flat : ∀ V : opens Y, G V → F (hf.comap V))
[f_flat_is_ring_hom : ∀ V : opens Y, is_ring_hom (f_flat V)]
(cont_f_flat : ∀ V : opens Y, continuous (f_flat V))
(presheaf_f_flat : ∀ V W : opens Y, ∀ (hWV : W ⊆ V),
  ∀ s : G V, F.res _ _ (hf.comap_mono hWV) (f_flat V s) = f_flat W (G.res V W hWV s))

instance presheaf_of_topological_rings.f_map_flat_is_ring_hom
  {X : Type u} [topological_space X] {Y : Type u} [topological_space Y]
  {F : presheaf_of_topological_rings X} {G : presheaf_of_topological_rings Y}
  (f : presheaf_of_topological_rings.f_map F G) (V : opens Y) :
  is_ring_hom (f.f_flat V) := f.f_flat_is_ring_hom V

attribute [instance] presheaf_of_topological_rings.f_map.f_flat_is_ring_hom

def presheaf_of_topological_rings.f_map.to_presheaf_of_rings_f_map
  {X : Type u} [topological_space X] {Y : Type u} [topological_space Y]
  {F : presheaf_of_topological_rings X} {G : presheaf_of_topological_rings Y}
  (f : presheaf_of_topological_rings.f_map F G) :
  presheaf_of_rings.f_map F.to_presheaf_of_rings G.to_presheaf_of_rings :=
{ ..f}

def presheaf_of_topological_rings.f_map_id
  {X : Type u} [topological_space X]
  {F : presheaf_of_topological_rings X} : presheaf_of_topological_rings.f_map F F :=
{ cont_f_flat := λ U, begin
      show continuous (((F.to_presheaf_of_rings).to_presheaf).res U (continuous.comap continuous_id U) _),
      convert continuous_id,
      { simp [continuous.comap_id U] },
      { simp [continuous.comap_id U] },
      convert heq_of_eq (F.Hid U),
        rw continuous.comap_id U,
      exact continuous.comap_id U,
    end,
  ..presheaf_of_rings.f_map_id F.to_presheaf_of_rings }

def presheaf_of_topological_rings.f_map_comp
  {X : Type u} [topological_space X] {Y : Type u} [topological_space Y]
  {Z : Type u} [topological_space Z] {F : presheaf_of_topological_rings X}
  {G : presheaf_of_topological_rings Y} {H : presheaf_of_topological_rings Z}
  (a : presheaf_of_topological_rings.f_map F G) (b : presheaf_of_topological_rings.f_map G H) :
  presheaf_of_topological_rings.f_map F H :=
{ cont_f_flat := λ V, (a.cont_f_flat _).comp (b.cont_f_flat _),
  ..presheaf_of_rings.f_map_comp a.to_presheaf_of_rings_f_map b.to_presheaf_of_rings_f_map }
-- need a construction `stalk_map` attached to an f-map; should follow from UMP
-- Need this before we embark on 𝒞.map

local attribute [instance, priority 0] classical.prop_decidable

/-- The map on stalks induced from an f-map -/
noncomputable def stalk_map {X : Type u} [topological_space X] {Y : Type u} [topological_space Y]
  {F : presheaf_of_rings X} {G : presheaf_of_rings Y} (f : presheaf_of_rings.f_map F G)
  (x : X) : stalk_of_rings G (f.f x) → stalk_of_rings F x :=
to_stalk.rec G (f.f x) (stalk_of_rings F x)
  (λ V hfx s, ⟦⟨f.hf.comap V, hfx, f.f_flat V s⟩⟧)
  (λ V W H r hfx, quotient.sound begin
    use [f.hf.comap V, hfx, set.subset.refl _, f.hf.comap_mono H],
    erw F.to_presheaf.Hid,
    symmetry,
    apply f.presheaf_f_flat
  end )

instance {X : Type u} [topological_space X] {F : presheaf_of_rings X} (x : X) :
  comm_ring (quotient (stalk.setoid (F.to_presheaf) x)) :=
stalk_of_rings_is_comm_ring F x

instance f_flat_is_ring_hom {X : Type u} [topological_space X] {Y : Type u} [topological_space Y]
  {F : presheaf_of_rings X} {G : presheaf_of_rings Y} (f : presheaf_of_rings.f_map F G)
  (x : X) (V : opens Y) (hfx : f.f x ∈ V) :
  is_ring_hom (λ (s : G.F V), (⟦⟨f.hf.comap V, hfx, f.f_flat V s⟩⟧ : stalk_of_rings F x)) :=
begin
  show is_ring_hom ((to_stalk F x (f.hf.comap V) hfx) ∘ (f.f_flat V)),
  refine is_ring_hom.comp _ _,
end

instance {X : Type u} [topological_space X] {Y : Type u} [topological_space Y]
  {F : presheaf_of_rings X} {G : presheaf_of_rings Y} (f : presheaf_of_rings.f_map F G)
  (x : X) : is_ring_hom (stalk_map f x) := to_stalk.rec_is_ring_hom _ _ _ _ _

lemma stalk_map_id {X : Type u} [topological_space X]
  (F : presheaf_of_rings X) (x : X) (s : stalk_of_rings F x) :
  stalk_map (presheaf_of_rings.f_map_id F) x s = s :=
begin
  induction s,
    apply quotient.sound,
    use s.U,
    use s.HxU,
    use (le_refl s.U),
    use (le_refl s.U),
    symmetry,
    convert (F.to_presheaf.Hcomp' _ _ _ _ _ s.s),
  refl,
end

lemma stalk_map_id' {X : Type u} [topological_space X]
  (F : presheaf_of_rings X) (x : X) :
  stalk_map (presheaf_of_rings.f_map_id F) x = id := by ext; apply stalk_map_id

lemma stalk_map_comp {X : Type u} [topological_space X]
  {Y : Type u} [topological_space Y] {Z : Type u} [topological_space Z]
   {F : presheaf_of_rings X}
  {G : presheaf_of_rings Y} {H : presheaf_of_rings Z}
  (a : presheaf_of_rings.f_map F G) (b : presheaf_of_rings.f_map G H) (x : X)
  (s : stalk_of_rings H (b.f (a.f x))) :
  stalk_map (presheaf_of_rings.f_map_comp a b) x s =
  stalk_map a x (stalk_map b (a.f x) s) :=
begin
  induction s,
    apply quotient.sound,
    use a.hf.comap (b.hf.comap s.U),
    use s.HxU,
    existsi _, swap, intros t ht, exact ht,
    existsi _, swap, intros t ht, exact ht,
    refl,
  refl,
end


lemma stalk_map_comp' {X : Type u} [topological_space X]
  {Y : Type u} [topological_space Y] {Z : Type u} [topological_space Z]
  {F : presheaf_of_rings X}
  {G : presheaf_of_rings Y} {H : presheaf_of_rings Z}
  (a : presheaf_of_rings.f_map F G) (b : presheaf_of_rings.f_map G H) (x : X) :
  stalk_map (presheaf_of_rings.f_map_comp a b) x =
  (stalk_map a x) ∘ (stalk_map b (a.f x)) := by ext; apply stalk_map_comp

namespace PreValuedRingedSpace
open category_theory

structure hom (X Y : PreValuedRingedSpace.{u}) :=
(fmap : presheaf_of_topological_rings.f_map X.presheaf Y.presheaf)
(stalk : ∀ x : X, ((X.valuation x).out.comap (stalk_map fmap.to_presheaf_of_rings_f_map x)).is_equiv
  (Y.valuation (fmap.f x)).out)

lemma hom_ext {X Y : PreValuedRingedSpace.{u}} (f g : hom X Y) :
  f.fmap = g.fmap → f = g :=
by { cases f, cases g, tidy }

def id (X : PreValuedRingedSpace.{u}) : hom X X :=
{ fmap := presheaf_of_topological_rings.f_map_id,
  stalk := λ x, begin
    show valuation.is_equiv
    (valuation.comap (Spv.out (X.valuation x))
       (stalk_map
          (presheaf_of_rings.f_map_id X.presheaf.to_presheaf_of_rings)
          x))
    (Spv.out (X.valuation ((λ (x : X), x) x))),
    simp only [stalk_map_id' X.presheaf.to_presheaf_of_rings x],
    convert valuation.is_equiv.refl,
    unfold valuation.comap,
    dsimp,
    unfold_coes,
    rw subtype.ext,
  end }

def comp {X Y Z : PreValuedRingedSpace.{u}} (f : hom X Y) (g : hom Y Z) : hom X Z :=
{ fmap := presheaf_of_topological_rings.f_map_comp f.fmap g.fmap,
  stalk := λ x, begin refine valuation.is_equiv.trans _ (g.stalk (f.fmap.f x)),
    let XXX := f.stalk x,
    let YYY := valuation.is_equiv.comap (stalk_map (presheaf_of_topological_rings.f_map.to_presheaf_of_rings_f_map (g.fmap))
          ((presheaf_of_topological_rings.f_map.to_presheaf_of_rings_f_map (f.fmap)).f x)) XXX,
    show valuation.is_equiv _ (valuation.comap (Spv.out (Y.valuation ((f.fmap).f x))) _),
    refine valuation.is_equiv.trans _ YYY,
    rw ←valuation.comap_comp,
    suffices : (stalk_map
          (presheaf_of_topological_rings.f_map.to_presheaf_of_rings_f_map
             (presheaf_of_topological_rings.f_map_comp (f.fmap) (g.fmap)))
          x) = (stalk_map (presheaf_of_topological_rings.f_map.to_presheaf_of_rings_f_map (f.fmap)) x ∘
          stalk_map (presheaf_of_topological_rings.f_map.to_presheaf_of_rings_f_map (g.fmap))
            ((presheaf_of_topological_rings.f_map.to_presheaf_of_rings_f_map (f.fmap)).f x)),
      simp [this],
    rw ←stalk_map_comp',
    refl,
  end }

instance large_category : large_category (PreValuedRingedSpace.{u}) :=
{ hom  := hom,
  id   := id,
  comp := λ X Y Z f g, comp f g,
  id_comp' :=
  begin
    intros X Y f,
    apply hom_ext,
    cases f, cases f_fmap,
    cases X, cases X_presheaf, cases X_presheaf__to_presheaf_of_rings,
    cases X_presheaf__to_presheaf_of_rings__to_presheaf,
    dsimp [id, comp, continuous.comap, presheaf_of_rings.f_map_id, presheaf_of_rings.f_map_comp,
      presheaf_of_topological_rings.f_map.to_presheaf_of_rings_f_map,
      presheaf_of_topological_rings.f_map_comp, presheaf_of_topological_rings.f_map_id] at *,
    congr,
    clear f_stalk, funext,
    exact congr_fun (X_presheaf__to_presheaf_of_rings__to_presheaf_Hid ⟨f_fmap_f ⁻¹' V.val, _⟩) (f_fmap_f_flat V s)
  end,
  comp_id' :=
  begin
    intros X Y f,
    apply hom_ext,
    cases f, cases f_fmap,
    dsimp,
    cases Y, cases Y_presheaf, cases Y_presheaf__to_presheaf_of_rings,
    cases Y_presheaf__to_presheaf_of_rings__to_presheaf,
    dsimp [id, comp, continuous.comap, presheaf_of_rings.f_map_id, presheaf_of_rings.f_map_comp,
      presheaf_of_topological_rings.f_map.to_presheaf_of_rings_f_map,
      presheaf_of_topological_rings.f_map_comp, presheaf_of_topological_rings.f_map_id] at *,
    congr,
    clear f_stalk, funext,
    have H2 : f_fmap_f_flat V
      (Y_presheaf__to_presheaf_of_rings__to_presheaf_res V V _ s) =
      f_fmap_f_flat V s,
      rw Y_presheaf__to_presheaf_of_rings__to_presheaf_Hid V, refl,
    convert H2,
      apply opens.ext,refl,
      apply opens.ext,refl,
  end }

end PreValuedRingedSpace

def presheaf_of_rings.restrict {X : Type u} [topological_space X] (U : opens X)
  (G : presheaf_of_rings X) : presheaf_of_rings U :=
  { F := λ V, G.F (topological_space.opens.map U V),
    res := λ V W HWV, G.res _ _ (topological_space.opens.map_mono HWV),
    Hid := λ V, G.Hid (topological_space.opens.map U V),
    Hcomp := λ V₁ V₂ V₃ H12 H23, G.Hcomp (topological_space.opens.map U V₁)
      (topological_space.opens.map U V₂) (topological_space.opens.map U V₃)
      (topological_space.opens.map_mono H12) (topological_space.opens.map_mono H23),
    Fring := λ V, G.Fring (topological_space.opens.map U V),
    res_is_ring_hom := λ V W HWV, G.res_is_ring_hom (topological_space.opens.map U V)
      (topological_space.opens.map U W) (topological_space.opens.map_mono HWV) }

noncomputable def presheaf_of_rings.restrict_stalk_map {X : Type u} [topological_space X]
  {U : opens X} (G : presheaf_of_rings X) (u : U) :
  stalk_of_rings (presheaf_of_rings.restrict U G) u → stalk_of_rings G u :=
to_stalk.rec (presheaf_of_rings.restrict U G) u (stalk_of_rings G u)
  (λ V hu, to_stalk G u (topological_space.opens.map U V) ( opens.map_mem_of_mem hu))
  (λ W V HWV s huW, quotient.sound (begin
    use [(topological_space.opens.map U W), opens.map_mem_of_mem huW],
    use [(set.subset.refl (topological_space.opens.map U W)), topological_space.opens.map_mono HWV],
    rw G.Hid (topological_space.opens.map U W),
    refl,
  end))

instance {X : Type u} [topological_space X] {U : opens X} (G : presheaf_of_rings X) (u : U) :
  is_ring_hom (presheaf_of_rings.restrict_stalk_map G u) :=
by unfold presheaf_of_rings.restrict_stalk_map; apply_instance

def presheaf_of_topological_rings.restrict {X : Type u} [topological_space X] (U : opens X)
  (G : presheaf_of_topological_rings X) : presheaf_of_topological_rings U :=
  { Ftop := λ V, G.Ftop (topological_space.opens.map U V),
    Ftop_ring := λ V, G.Ftop_ring (topological_space.opens.map U V),
    res_continuous := λ V W HWV, G.res_continuous (topological_space.opens.map U V)
      (topological_space.opens.map U W) (topological_space.opens.map_mono HWV),
  ..presheaf_of_rings.restrict U G.to_presheaf_of_rings }

noncomputable instance PreValuedRingedSpace.restrict {X : PreValuedRingedSpace.{u}} :
  has_coe (opens X) PreValuedRingedSpace :=
{ coe := λ U,
  { space := U,
    top := by apply_instance,
    presheaf := presheaf_of_topological_rings.restrict U X.presheaf,
    valuation :=
      λ u, Spv.mk (valuation.comap (X.valuation u).out (presheaf_of_rings.restrict_stalk_map _ _)) } }

section
local attribute [instance] sheaf_of_topological_rings.uniform_space

/--Category of topological spaces endowed with a sheaf of complete topological rings
and (an equivalence class of) valuations on the stalks (which are required to be local
rings; moreover the support of the valuation must be the maximal ideal of the stalk).
Wedhorn calls this category `𝒱`.-/
structure CLVRS :=
(space : Type) -- change this to (Type u) to enable universes
(top   : topological_space space)
(sheaf : sheaf_of_topological_rings.{0 0} space)
(complete : ∀ U : opens space, complete_space (sheaf.F.F U))
(valuation : ∀ x : space, Spv (stalk_of_rings sheaf.to_presheaf_of_topological_rings.to_presheaf_of_rings x))
(local_stalks : ∀ x : space, is_local_ring (stalk_of_rings sheaf.to_presheaf_of_rings x))
(supp_maximal : ∀ x : space, ideal.is_maximal (_root_.valuation.supp (valuation x).out))

end

namespace CLVRS
open category_theory

def to_PreValuedRingedSpace (X : CLVRS) : PreValuedRingedSpace.{0} :=
{ presheaf := _, ..X }

instance : has_coe CLVRS PreValuedRingedSpace.{0} :=
⟨to_PreValuedRingedSpace⟩

instance : large_category CLVRS := induced_category.category to_PreValuedRingedSpace

end CLVRS

/--The adic spectrum of a Huber pair.-/
noncomputable def Spa (A : Huber_pair) : PreValuedRingedSpace :=
{ space     := spa A,
  top       := by apply_instance,
  presheaf  := spa.presheaf_of_topological_rings A,
  valuation := λ x, Spv.mk (spa.presheaf.stalk_valuation x) }

open lattice

-- Notation for the proposition that an isomorphism exists between A and B
notation A `≊` B := nonempty (A ≅ B)

namespace CLVRS

def is_adic_space (X : CLVRS) : Prop :=
∀ x : X, ∃ (U : opens X) (R : Huber_pair), x ∈ U ∧ (Spa R ≊ U)

end CLVRS

def AdicSpace := {X : CLVRS // X.is_adic_space}

namespace AdicSpace
open category_theory

instance : large_category AdicSpace := category_theory.full_subcategory _

end AdicSpace

-- #doc_blame!
-- #sanity_check
