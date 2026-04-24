"use client";

import { useState } from "react";
import Image from "next/image";
import { api } from "~/trpc/react";

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
  description: string;
  image: string;
  options: CakeOptionInput[];
}

const INITIAL_FORM: CakeFormData = {
  name: "",
  description: "",
  image: "",
  options: [{ size: "", serves: "", price: "" }],
};

// ─── Page Component ─────────────────────────────────────────────────────────

export default function AdminMenuPage() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formData, setFormData] = useState<CakeFormData>(INITIAL_FORM);
  const [isEditing, setIsEditing] = useState(false);

  const utils = api.useUtils();
  const cakesQuery = api.cake.getAll.useQuery();

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

  const openModal = (cake?: { id: string; name: string; description: string | null; image: string; options: CakeOptionInput[] }) => {
    if (cake) {
      setFormData({
        id: cake.id,
        name: cake.name,
        description: cake.description ?? "",
        image: cake.image,
        options: cake.options.map((o) => ({
          id: o.id,
          size: o.size,
          serves: o.serves,
          price: o.price,
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
    if (isEditing && formData.id) {
      updateMutation.mutate(formData as { id: string; name: string; image: string; options: CakeOptionInput[]; description?: string });
    } else {
      createMutation.mutate(formData as { name: string; image: string; options: CakeOptionInput[]; description?: string });
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
          <button
            onClick={() => openModal()}
            className="bg-[#F4C2C2] text-[#2B2B2B] px-6 py-2 rounded-full font-medium hover:bg-[#E8DED4] transition-all shadow-soft"
          >
            + Add New Cake
          </button>
        </div>

        {/* Grid */}
        {cakesQuery.isLoading ? (
          <div className="text-center py-20 text-[#9A9A9A]">Loading menu...</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {cakesQuery.data?.map((cake) => (
              <div key={cake.id} className="bg-white rounded-2xl overflow-hidden shadow-soft border border-[#E8DED4] group">
                <div className="relative h-48 w-full">
                  <Image
                    src={cake.image}
                    alt={cake.name}
                    fill
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
                  <h3 className="text-lg font-heading text-[#2B2B2B] mb-2">{cake.name}</h3>
                  <p className="text-sm text-[#9A9A9A] mb-4 line-clamp-2">{cake.description}</p>
                  <div className="space-y-2">
                    {cake.options.map((opt) => (
                      <div key={opt.id} className="flex justify-between text-xs font-body border-t border-[#F7F3EF] pt-2">
                        <span className="text-[#6E6E6E]">{opt.size} ({opt.serves} pers)</span>
                        <span className="text-[#F4C2C2] font-semibold">{opt.price}</span>
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
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
            <div className="bg-white rounded-3xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col shadow-2xl">
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
                    <label className="text-sm font-semibold text-[#6E6E6E]">Image URL</label>
                    <input
                      required
                      className="w-full p-3 rounded-xl border border-[#E8DED4] focus:ring-2 focus:ring-[#F4C2C2] outline-none"
                      value={formData.image}
                      onChange={(e) => setFormData({ ...formData, image: e.target.value })}
                      placeholder="https://..."
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-semibold text-[#6E6E6E]">Description</label>
                  <textarea
                    rows={3}
                    className="w-full p-3 rounded-xl border border-[#E8DED4] focus:ring-2 focus:ring-[#F4C2C2] outline-none"
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    placeholder="Describe the flavors..."
                  />
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
