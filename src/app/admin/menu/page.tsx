"use client";

import { useState } from "react";
import Image from "next/image";
import { api } from "~/trpc/react";
import { formatPrice } from "~/lib/format";

// ─── Types ──────────────────────────────────────────────────────────────────

interface CakeOptionInput {
  id?: string;
  size: string;
  serves: string;
  price: string;
}

interface CakeFormData {
  id?: string;
  name: string;
  slug: string;
  description: string;
  category: string;
  categoryId: string;
  image: string;
  isAvailable: boolean;
  sortOrder: number;
  options: CakeOptionInput[];
}

const INITIAL_FORM: CakeFormData = {
  name: "",
  slug: "",
  description: "",
  category: "",
  categoryId: "",
  image: "",
  isAvailable: true,
  sortOrder: 0,
  options: [{ size: "", serves: "", price: "" }],
};

// ─── Page Component ─────────────────────────────────────────────────────────

export default function AdminMenuPage() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formData, setFormData] = useState<CakeFormData>(INITIAL_FORM);
  const [isEditing, setIsEditing] = useState(false);

  const utils = api.useUtils();
  const cakesQuery = api.cake.getAll.useQuery();
  const categoriesQuery = api.cake.getAllCategories.useQuery();
  const [categoryFilter, setCategoryFilter] = useState<string>("All");

  const createMutation = api.cake.create.useMutation({
    onSuccess: () => {
      void utils.cake.getAll.invalidate();
      closeModal();
    },
  });

  const updateMutation = api.cake.update.useMutation({
    onSuccess: () => {
      void utils.cake.getAll.invalidate();
      closeModal();
    },
  });

  const deleteMutation = api.cake.delete.useMutation({
    onSuccess: () => {
      void utils.cake.getAll.invalidate();
    },
  });

  // ─── Handlers ──────────────────────────────────────────────────────────────

  const openModal = (cake?: {
    id: string;
    name: string;
    slug: string;
    description: string | null;
    category?: { id: string, name: string } | null;
    categoryName?: string | null;
    categoryId?: string | null;
    image: string;
    isAvailable: boolean;
    sortOrder: number;
    options: { id: string; size: string; serves: string; price: number; cakeId: string }[]
  }) => {
    if (cake) {
      setFormData({
        id: cake.id,
        name: cake.name,
        slug: cake.slug,
        description: cake.description ?? "",
        category: cake.category?.name ?? cake.categoryName ?? "",
        categoryId: cake.category?.id ?? cake.categoryId ?? "",
        image: cake.image,
        isAvailable: cake.isAvailable,
        sortOrder: cake.sortOrder,
        options: cake.options.map((o) => ({
          id: o.id,
          size: o.size,
          serves: o.serves,
          price: o.price.toString(),
        })),
      });
      setIsEditing(true);
    } else {
      setFormData(INITIAL_FORM);
      setIsEditing(false);
    }
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setFormData(INITIAL_FORM);
  };

  const handleOptionChange = (index: number, field: keyof CakeOptionInput, value: string) => {
    const newOptions = [...formData.options];
    if (newOptions[index]) {
      newOptions[index] = { ...newOptions[index], [field]: value };
      setFormData({ ...formData, options: newOptions });
    }
  };

  const addOption = () => {
    setFormData({
      ...formData,
      options: [...formData.options, { size: "", serves: "", price: "" }],
    });
  };

  const removeOption = (index: number) => {
    const newOptions = formData.options.filter((_, i) => i !== index);
    setFormData({ ...formData, options: newOptions });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const submissionData = {
      ...formData,
      options: formData.options.map(opt => ({
        ...opt,
        price: parseInt(opt.price.toString().replace(/[^\d]/g, ""), 10) || 0
      }))
    };

    if (isEditing && formData.id) {
      updateMutation.mutate(submissionData as { 
        id: string; 
        name: string; 
        slug?: string;
        image: string; 
        options: { size: string; serves: string; price: number; id?: string }[]; 
        description?: string; 
        category?: string;
        categoryId?: string;
        isAvailable?: boolean;
        sortOrder?: number;
      });
    } else {
      createMutation.mutate(submissionData as { 
        name: string; 
        slug?: string;
        image: string; 
        options: { size: string; serves: string; price: number }[]; 
        description?: string; 
        category?: string;
        categoryId?: string;
        isAvailable?: boolean;
        sortOrder?: number;
      });
    }
  };


  return (
    <div className="min-h-screen bg-[#FFF9F7] p-8">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-heading text-[#2B2B2B] mb-1">Menu Management</h1>
            <p className="text-[#9A9A9A]">Add or edit cakes shown on the landing page</p>
          </div>
          <div className="flex gap-4 items-center">
            <select
              className="p-2 rounded-xl border border-[#E8DED4] bg-white text-sm outline-none"
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
            >
              <option value="All">All Categories</option>
              {categoriesQuery.data?.map(cat => (
                <option key={cat.id} value={cat.id}>{cat.name}</option>
              ))}
            </select>
            <button
              onClick={() => openModal()}
              className="bg-[#F4C2C2] text-[#2B2B2B] px-6 py-2 rounded-full font-medium hover:bg-[#E8DED4] transition-all shadow-soft"
            >
              + Add New
            </button>
          </div>
        </div>

        {/* Grid */}
        {cakesQuery.isLoading ? (
          <div className="text-center py-20 text-[#9A9A9A]">Loading menu...</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {cakesQuery.data
              ?.filter((c) => categoryFilter === "All" || c.categoryId === categoryFilter || c.category?.id === categoryFilter)
              .map((cake) => (
              <div key={cake.id} className={`bg-white rounded-2xl overflow-hidden shadow-soft border border-[#E8DED4] group relative ${!cake.isAvailable ? "grayscale-[0.5] opacity-80" : ""}`}>
                {!cake.isAvailable && (
                  <div className="absolute top-4 left-4 z-10 bg-red-500 text-white text-[10px] font-bold px-2 py-1 rounded-full uppercase tracking-wider">
                    Unavailable
                  </div>
                )}
                <div className="relative h-48 w-full">
                  <Image
                    src={cake.image}
                    alt={cake.name}
                    fill
                    unoptimized
                    className="object-cover"
                  />
                  <div className="absolute top-2 right-2 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                      onClick={() => openModal(cake)}
                      className="bg-white/90 p-2 rounded-full shadow-md hover:bg-white text-blue-600"
                    >
                      ✏️
                    </button>
                    <button
                      onClick={() => {
                        if (confirm("Are you sure you want to delete this cake?")) {
                          deleteMutation.mutate({ id: cake.id });
                        }
                      }}
                      className="bg-white/90 p-2 rounded-full shadow-md hover:bg-white text-red-600"
                    >
                      🗑️
                    </button>
                  </div>
                </div>
                <div className="p-6">
                  <div className="flex justify-between items-start mb-2">
                    <h3 className="text-lg font-heading text-[#2B2B2B]">{cake.name}</h3>
                    <span className="text-[10px] bg-[#F4C2C2]/20 text-[#F4C2C2] px-2 py-1 rounded-full uppercase tracking-wider font-bold">
                      {cake.category?.name ?? "General"}
                    </span>
                  </div>
                  <p className="text-sm text-[#9A9A9A] mb-4 line-clamp-2">{cake.description}</p>
                  <div className="space-y-2">
                    {cake.options.map((opt) => (
                      <div key={opt.id} className="flex justify-between text-xs font-body border-t border-[#F7F3EF] pt-2">
                        <span className="text-[#6E6E6E]">{opt.size} ({opt.serves} pers)</span>
                        <span className="text-[#F4C2C2] font-semibold">{formatPrice(opt.price)}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Modal */}
        {isModalOpen && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
            <div className="bg-white rounded-3xl w-full max-w-2xl min-w-[320px] md:min-w-[600px] max-h-[90vh] overflow-hidden flex flex-col shadow-2xl">
              <div className="p-6 border-b border-[#E8DED4] flex justify-between items-center">
                <h2 className="text-xl font-heading text-[#2B2B2B]">
                  {isEditing ? "Edit Cake" : "Add New Cake"}
                </h2>
                <button onClick={closeModal} className="text-[#9A9A9A] hover:text-[#2B2B2B]">✕</button>
              </div>

              <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6">
                {/* Basic Info */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <label className="text-sm font-semibold text-[#6E6E6E]">Cake Name</label>
                    <input
                      required
                      className="w-full p-3 rounded-xl border border-[#E8DED4] focus:ring-2 focus:ring-[#F4C2C2] outline-none"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      placeholder="e.g. Belgian Chocolate Truffle"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-semibold text-[#6E6E6E]">Category</label>
                    <select
                      className="w-full p-3 rounded-xl border border-[#E8DED4] focus:ring-2 focus:ring-[#F4C2C2] outline-none bg-white"
                      value={formData.categoryId}
                      onChange={(e) => {
                        const cat = categoriesQuery.data?.find(c => c.id === e.target.value);
                        setFormData({ 
                          ...formData, 
                          categoryId: e.target.value,
                          category: cat?.name ?? "" 
                        });
                      }}
                    >
                      <option value="">Select Category</option>
                      {categoriesQuery.data?.map(cat => (
                        <option key={cat.id} value={cat.id}>{cat.name}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <label className="text-sm font-semibold text-[#6E6E6E]">Slug (Auto-generated if empty)</label>
                    <input
                      className="w-full p-3 rounded-xl border border-[#E8DED4] focus:ring-2 focus:ring-[#F4C2C2] outline-none"
                      value={formData.slug}
                      onChange={(e) => setFormData({ ...formData, slug: e.target.value })}
                      placeholder="e.g. belgian-chocolate"
                    />
                  </div>
                  <div className="flex gap-6 pt-8">
                    <div className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        id="isAvailable"
                        className="w-5 h-5 rounded border-[#E8DED4] text-[#F4C2C2] focus:ring-[#F4C2C2]"
                        checked={formData.isAvailable}
                        onChange={(e) => setFormData({ ...formData, isAvailable: e.target.checked })}
                      />
                      <label htmlFor="isAvailable" className="text-sm font-semibold text-[#6E6E6E]">Available</label>
                    </div>
                    <div className="flex items-center gap-2 flex-1">
                      <label className="text-sm font-semibold text-[#6E6E6E] shrink-0">Sort Order</label>
                      <input
                        type="number"
                        className="w-20 p-2 rounded-xl border border-[#E8DED4] outline-none text-sm"
                        value={formData.sortOrder}
                        onChange={(e) => setFormData({ ...formData, sortOrder: parseInt(e.target.value, 10) || 0 })}
                      />
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <label className="text-sm font-semibold text-[#6E6E6E]">Image</label>
                    <div className="flex gap-2">
                      <input
                        required
                        className="flex-1 p-3 rounded-xl border border-[#E8DED4] focus:ring-2 focus:ring-[#F4C2C2] outline-none text-sm"
                        value={formData.image}
                        onChange={(e) => setFormData({ ...formData, image: e.target.value })}
                        placeholder="Image URL or upload..."
                      />
                      <label className="cursor-pointer bg-[#E8DED4] text-[#2B2B2B] px-4 py-3 rounded-xl hover:bg-[#D8CDBC] transition-colors flex items-center justify-center">
                        <span className="text-lg">📷</span>
                        <input
                          type="file"
                          className="hidden"
                          accept="image/*"
                          onChange={async (e) => {
                            const file = e.target.files?.[0];
                            if (!file) return;

                            const btn = e.target.parentElement;
                            if (btn) btn.style.opacity = "0.5";

                            const formDataUpload = new FormData();
                            formDataUpload.append("file", file);

                            // Pass the slug so Supabase stores the image at a
                            // stable path (e.g. cakes/chocolate-indulgence.jpg).
                            // The URL never changes on re-upload — the WhatsApp
                            // bot always fetches the latest image automatically.
                            const uploadSlug = formData.slug.trim();
                            const uploadUrl = uploadSlug
                              ? `/api/upload?slug=${encodeURIComponent(uploadSlug)}`
                              : "/api/upload";

                            try {
                              const res = await fetch(uploadUrl, {
                                method: "POST",
                                body: formDataUpload,
                              });
                              const data = (await res.json()) as {
                                imageUrl?: string;
                                error?: string;
                                message?: string;
                              };

                              if (data.imageUrl) {
                                setFormData({ ...formData, image: data.imageUrl });
                              } else {
                                alert(`Upload failed: ${data.message ?? data.error ?? "Unknown error"}`);
                              }
                            } catch {
                              alert("Failed to upload image. Check your internet connection.");
                            } finally {
                              if (btn) btn.style.opacity = "1";
                              e.target.value = ""; // Reset to allow re-selecting same file
                            }
                          }}
                        />
                      </label>
                    </div>
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-semibold text-[#6E6E6E]">Description</label>
                  <div className="flex gap-4">
                    <textarea
                      rows={3}
                      className="flex-1 p-3 rounded-xl border border-[#E8DED4] focus:ring-2 focus:ring-[#F4C2C2] outline-none"
                      value={formData.description}
                      onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                      placeholder="Describe the flavors..."
                    />
                    {formData.image && (
                      <div className="relative w-24 h-24 rounded-xl overflow-hidden border border-[#E8DED4] shrink-0 bg-gray-50">
                        <Image
                          src={formData.image}
                          alt="Preview"
                          fill
                          unoptimized
                          className="object-cover"
                        />
                      </div>
                    )}
                  </div>
                </div>

                {/* Options */}
                <div className="space-y-4">
                  <div className="flex justify-between items-center">
                    <label className="text-sm font-semibold text-[#6E6E6E]">Pricing Options</label>
                    <button
                      type="button"
                      onClick={addOption}
                      className="text-sm text-[#F4C2C2] font-semibold hover:underline"
                    >
                      + Add Size
                    </button>
                  </div>

                  {formData.options.map((opt, idx) => (
                    <div key={idx} className="flex gap-4 items-end bg-[#FFF9F7] p-4 rounded-2xl border border-[#F4C2C2]/20">
                      <div className="flex-1 space-y-1">
                        <span className="text-[10px] uppercase tracking-wider text-[#9A9A9A]">Size</span>
                        <input
                          required
                          className="w-full p-2 bg-transparent border-b border-[#E8DED4] focus:border-[#F4C2C2] outline-none text-sm"
                          value={opt.size}
                          onChange={(e) => handleOptionChange(idx, "size", e.target.value)}
                          placeholder="600g"
                        />
                      </div>
                      <div className="flex-1 space-y-1">
                        <span className="text-[10px] uppercase tracking-wider text-[#9A9A9A]">Serves</span>
                        <input
                          required
                          className="w-full p-2 bg-transparent border-b border-[#E8DED4] focus:border-[#F4C2C2] outline-none text-sm"
                          value={opt.serves}
                          onChange={(e) => handleOptionChange(idx, "serves", e.target.value)}
                          placeholder="4-6"
                        />
                      </div>
                      <div className="flex-1 space-y-1">
                        <span className="text-[10px] uppercase tracking-wider text-[#9A9A9A]">Price</span>
                        <input
                          required
                          className="w-full p-2 bg-transparent border-b border-[#E8DED4] focus:border-[#F4C2C2] outline-none text-sm"
                          value={opt.price}
                          onChange={(e) => handleOptionChange(idx, "price", e.target.value)}
                          placeholder="₹750"
                        />
                      </div>
                      {formData.options.length > 1 && (
                        <button
                          type="button"
                          onClick={() => removeOption(idx)}
                          className="p-2 text-red-400 hover:text-red-600"
                        >
                          🗑️
                        </button>
                      )}
                    </div>
                  ))}
                </div>

                <div className="pt-4 flex gap-4">
                  <button
                    type="button"
                    onClick={closeModal}
                    className="flex-1 p-3 rounded-xl border border-[#E8DED4] font-semibold text-[#6E6E6E] hover:bg-gray-50"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={createMutation.isPending || updateMutation.isPending}
                    className="flex-1 p-3 rounded-xl bg-[#2B2B2B] text-white font-semibold hover:bg-black transition-all disabled:opacity-50"
                  >
                    {isEditing ? (updateMutation.isPending ? "Updating..." : "Save Changes") : (createMutation.isPending ? "Creating..." : "Add to Menu")}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
// hi