import React, { useState } from 'react';
import { Search, Plus, Phone, MessageCircle, Package, ChevronRight, RefreshCw } from 'lucide-react';
import { SUPPLIERS } from '../constants';
import { motion } from 'motion/react';

export const SupplierDirectoryScreen: React.FC = () => {
  const [search, setSearch] = useState('');

  const filteredSuppliers = SUPPLIERS.filter(s => 
    s.name.toLowerCase().includes(search.toLowerCase()) || 
    s.city.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="flex flex-col h-full">
      <div className="px-4 py-4 space-y-4">
        <div className="relative group">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-[#007fff] transition-colors" size={18} />
          <input 
            className="w-full pl-10 pr-4 py-3 bg-white border-none rounded-xl shadow-sm focus:ring-2 focus:ring-[#007fff]/50 text-sm font-medium placeholder:text-slate-400 transition-all" 
            placeholder="Search suppliers, parts or cities..." 
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div className="flex gap-2 overflow-x-auto no-scrollbar pb-1">
          <button className="whitespace-nowrap px-4 py-2 rounded-full bg-[#007fff] text-white text-xs font-bold">All Suppliers</button>
          <button className="whitespace-nowrap px-4 py-2 rounded-full bg-white border border-slate-200 text-slate-600 text-xs font-bold">Membranes</button>
          <button className="whitespace-nowrap px-4 py-2 rounded-full bg-white border border-slate-200 text-slate-600 text-xs font-bold">Pumps</button>
          <button className="whitespace-nowrap px-4 py-2 rounded-full bg-white border border-slate-200 text-slate-600 text-xs font-bold">Filters</button>
        </div>
      </div>

      <main className="flex-1 px-4 space-y-4 pb-24">
        <h3 className="text-xs font-bold uppercase tracking-widest text-slate-500 mt-2">Verified Partners ({filteredSuppliers.length})</h3>
        
        {filteredSuppliers.map((supplier, index) => (
          <motion.div
            key={supplier.id}
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: index * 0.05 }}
            className={`bg-white rounded-xl shadow-sm border border-slate-100 overflow-hidden ${supplier.status === 'inactive' ? 'opacity-80' : ''}`}
          >
            <div className="p-4">
              <div className="flex justify-between items-start mb-3">
                <div>
                  <div className="flex items-center gap-2">
                    <h2 className="text-lg font-bold text-slate-900">{supplier.name}</h2>
                    {supplier.status === 'active' ? (
                      <span className="flex size-2 rounded-full bg-green-500 ring-4 ring-green-100"></span>
                    ) : (
                      <span className="flex size-2 rounded-full bg-slate-300"></span>
                    )}
                  </div>
                  <p className="text-sm text-slate-500">{supplier.contactPerson} • {supplier.city}</p>
                </div>
                <div className="flex gap-2">
                  <button className="size-10 rounded-full bg-[#007fff]/10 text-[#007fff] flex items-center justify-center active:scale-90 transition-transform">
                    <Phone size={18} />
                  </button>
                  <button className="size-10 rounded-full bg-green-500/10 text-green-600 flex items-center justify-center active:scale-90 transition-transform">
                    <MessageCircle size={18} />
                  </button>
                </div>
              </div>

              <div className="flex flex-wrap gap-2 mb-4">
                {supplier.specialties.map(spec => (
                  <span key={spec} className="px-2 py-1 bg-slate-100 rounded-md text-[10px] font-bold text-slate-600 uppercase">{spec}</span>
                ))}
                {supplier.specialties.length > 2 && <span className="px-2 py-1 bg-slate-100 rounded-md text-[10px] font-bold text-slate-600 uppercase">+3 More</span>}
              </div>

              <div className="pt-4 border-t border-slate-100 flex items-center justify-between">
                <div className="flex items-center gap-1.5">
                  {supplier.activePOs > 0 ? (
                    <>
                      <Package size={14} className="text-slate-400" />
                      <p className="text-xs font-medium text-slate-500">{supplier.activePOs} Active POs</p>
                    </>
                  ) : (
                    <>
                      <RefreshCw size={14} className="text-slate-400" />
                      <p className="text-xs font-medium text-slate-500">Last order 2mo ago</p>
                    </>
                  )}
                </div>
                <button className="text-sm font-bold text-[#007fff] flex items-center gap-1 hover:underline">
                  {supplier.activePOs > 0 ? 'View Purchase Orders' : 'Reorder'}
                  <ChevronRight size={18} />
                </button>
              </div>
            </div>
          </motion.div>
        ))}
      </main>

      <button className="fixed bottom-24 right-6 bg-[#007fff] text-white p-4 rounded-2xl shadow-2xl shadow-[#007fff]/40 flex items-center gap-2 active:scale-95 transition-transform z-40">
        <Plus size={20} />
        <span className="text-sm font-extrabold pr-1">New PO</span>
      </button>
    </div>
  );
};
