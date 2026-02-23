import React, { useState } from 'react';
import { Search, Phone, History, UserPlus, Filter, Droplets } from 'lucide-react';
import { CUSTOMERS } from '../constants';
import { motion } from 'motion/react';

export const CustomerListScreen: React.FC<{ onSelectCustomer: (id: string) => void }> = ({ onSelectCustomer }) => {
  const [search, setSearch] = useState('');

  const filteredCustomers = CUSTOMERS.filter(c => 
    c.name.toLowerCase().includes(search.toLowerCase()) || 
    c.phone.includes(search) ||
    c.model.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="flex flex-col h-full">
      <div className="px-4 py-3 bg-white border-b border-slate-100">
        <div className="relative group mb-3">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search className="text-slate-400 group-focus-within:text-[#007fff] transition-colors" size={18} />
          </div>
          <input 
            className="block w-full pl-10 pr-3 py-2.5 bg-slate-100 border-none rounded-xl text-sm placeholder:text-slate-500 focus:ring-2 focus:ring-[#007fff]/50 transition-all" 
            placeholder="Search by name, contact, or model..." 
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div className="flex gap-2 overflow-x-auto no-scrollbar">
          <button className="flex items-center gap-1.5 px-4 py-1.5 bg-[#007fff] text-white rounded-full text-xs font-semibold shrink-0">
            <Filter size={14} />
            All Records
          </button>
          <button className="flex items-center gap-1.5 px-4 py-1.5 bg-slate-100 text-slate-600 rounded-full text-xs font-semibold shrink-0 border border-transparent hover:border-[#007fff]/30">
            Service Due
          </button>
          <button className="flex items-center gap-1.5 px-4 py-1.5 bg-slate-100 text-slate-600 rounded-full text-xs font-semibold shrink-0 border border-transparent hover:border-[#007fff]/30">
            Area: West Delhi
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3">
        {filteredCustomers.map((customer, index) => (
          <motion.div
            key={customer.id}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: index * 0.05 }}
            onClick={() => onSelectCustomer(customer.id)}
            className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm active:scale-[0.98] transition-transform"
          >
            <div className="flex justify-between items-start mb-2">
              <div>
                <h3 className="font-bold text-base text-slate-900">{customer.name}</h3>
                <p className="text-xs text-slate-500 font-medium">{customer.phone}</p>
              </div>
              <span className={`px-2 py-1 text-[10px] font-bold rounded uppercase tracking-wider ${
                customer.status === 'Service Due' ? 'bg-red-100 text-red-600 italic' :
                customer.status === 'Operational' ? 'bg-emerald-100 text-emerald-600' :
                customer.status === 'AMC Plan' ? 'bg-[#007fff]/10 text-[#007fff]' :
                'bg-amber-100 text-amber-600'
              }`}>
                {customer.status}
              </span>
            </div>
            <div className="flex items-center gap-2 mb-3">
              <Droplets className="text-[#007fff]" size={18} />
              <p className="text-sm text-slate-700">{customer.model}</p>
            </div>
            <div className="flex justify-between items-center pt-3 border-t border-slate-50">
              <div className="flex flex-col">
                <span className="text-[10px] text-slate-400 uppercase font-bold tracking-tight">Last Service</span>
                <span className="text-sm font-semibold text-slate-600">{customer.lastService}</span>
              </div>
              <div className="flex gap-2">
                <button className="p-2 bg-[#007fff]/10 text-[#007fff] rounded-lg">
                  <Phone size={18} />
                </button>
                <button className="p-2 bg-[#007fff]/10 text-[#007fff] rounded-lg">
                  <History size={18} />
                </button>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      <button className="fixed bottom-24 right-6 w-14 h-14 bg-[#007fff] text-white rounded-full shadow-lg flex items-center justify-center hover:scale-105 active:scale-95 transition-all z-30">
        <UserPlus size={28} />
      </button>
    </div>
  );
};
