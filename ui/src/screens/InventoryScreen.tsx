import React, { useState } from 'react';
import { Search, Plus, Upload, AlertCircle, Package, ChevronRight } from 'lucide-react';
import { INVENTORY } from '../constants';
import { motion } from 'motion/react';

export const InventoryScreen: React.FC<{ onNavigateToSuppliers: () => void }> = ({ onNavigateToSuppliers }) => {
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('All');

  const categories = ['All', 'Pumps', 'Membranes', 'Filters', 'UV Lamps'];

  const filteredInventory = INVENTORY.filter(item => 
    (category === 'All' || item.category === category) &&
    (item.name.toLowerCase().includes(search.toLowerCase()) || item.sku.toLowerCase().includes(search.toLowerCase()))
  );

  return (
    <div className="flex flex-col h-full">
      <div className="sticky top-0 z-20 bg-white/80 backdrop-blur-md px-4 pt-4 pb-2">
        <div className="flex items-center justify-between mb-4">
          <div className="flex gap-2">
            <button className="flex items-center justify-center w-10 h-10 rounded-full bg-[#007fff]/10 text-[#007fff] hover:bg-[#007fff]/20 transition-colors">
              <Upload size={20} />
            </button>
            <button className="flex items-center justify-center w-10 h-10 rounded-full bg-[#007fff] text-white shadow-lg shadow-[#007fff]/20">
              <Plus size={20} />
            </button>
          </div>
          <button 
            onClick={onNavigateToSuppliers}
            className="text-sm font-bold text-[#007fff] hover:underline"
          >
            Manage Suppliers
          </button>
        </div>

        <div className="relative mb-4">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search className="text-slate-400" size={18} />
          </div>
          <input 
            className="block w-full pl-10 pr-3 py-2.5 border-none bg-slate-200/50 rounded-xl focus:ring-2 focus:ring-[#007fff] text-sm placeholder-slate-500" 
            placeholder="Search SKU or item name..." 
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div className="flex gap-2 overflow-x-auto no-scrollbar pb-2">
          {categories.map(cat => (
            <button 
              key={cat}
              onClick={() => setCategory(cat)}
              className={`px-4 py-1.5 rounded-full text-sm font-semibold whitespace-nowrap transition-colors ${
                category === cat ? 'bg-[#007fff] text-white' : 'bg-white text-slate-600 border border-slate-200'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 px-4 py-2 space-y-3">
        {filteredInventory.map((item, index) => (
          <motion.div
            key={item.id}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.05 }}
            className="bg-white p-4 rounded-xl border border-slate-100 shadow-sm"
          >
            <div className="flex justify-between items-start mb-2">
              <div>
                <h3 className="font-bold text-slate-900">{item.name}</h3>
                <p className="text-xs text-slate-500">SKU: {item.sku} | Supplier: {item.supplier}</p>
              </div>
              <div className="text-right">
                <p className="font-bold text-[#007fff]">${item.price.toFixed(2)}</p>
              </div>
            </div>
            <div className="flex items-center justify-between mt-4">
              <div className={`flex items-center gap-2 px-2 py-1 rounded-lg ${
                item.stock <= item.lowStockThreshold ? 'bg-red-50 text-red-600' : 'bg-slate-100 text-slate-600'
              }`}>
                {item.stock <= item.lowStockThreshold ? <AlertCircle size={16} /> : <Package size={16} />}
                <span className="text-xs font-bold">{item.stock} in Stock {item.stock <= item.lowStockThreshold && '(Low)'}</span>
              </div>
              <button className="text-[#007fff] text-sm font-semibold flex items-center gap-1">
                Details <ChevronRight size={16} />
              </button>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
};
