import React from 'react';
import { Phone, MessageCircle, MapPin, Calendar, CheckCircle, ChevronRight, QrCode, MoreHorizontal, ArrowLeft } from 'lucide-react';
import { motion } from 'motion/react';

export const CustomerProfileScreen: React.FC = () => {
  const history = [
    { id: 1, title: 'Filter Replacement', date: 'Oct 24, 2023 • 11:30 AM', parts: ['Sediment Filter', 'Activated Carbon'], tech: 'Ravi Kumar', price: 120.00 },
    { id: 2, title: 'General Maintenance', date: 'Jul 12, 2023 • 02:15 PM', parts: ['None (Cleaning Only)'], tech: 'Amit Shah', price: 45.00 },
    { id: 3, title: 'Membrane Change', date: 'Jan 05, 2023 • 10:00 AM', parts: ['RO Membrane', 'FR 450'], tech: 'Ravi Kumar', price: 210.00 },
  ];

  return (
    <div className="flex flex-col h-full bg-[#f5f7f8]">
      <section className="p-4">
        <div className="bg-white rounded-xl p-5 shadow-sm border border-slate-100">
          <div className="flex items-start justify-between mb-6">
            <div className="flex gap-4">
              <div className="size-20 rounded-xl bg-[#007fff]/10 flex items-center justify-center overflow-hidden border border-[#007fff]/20">
                <img 
                  alt="Eleanor Pena" 
                  className="w-full h-full object-cover" 
                  src="https://lh3.googleusercontent.com/aida-public/AB6AXuCglsoH-BBzaT6911tk8ROEVRlYpiMrCzyr4RFDALkb9kJJBf-v9kSToxHMD3bskCqKLcM-Axm8b252AvnvKeKBodeB6bC40wucIQjqI3PLX8ByE-MWqOeXbYkjdlW942egsWmQpwN-0oUnABS4QyVbGxJbX_P_Sq5Lcxi05kd0wu75txRIbEByMRKHroe0W6SSM8okvcgA9tzJja7L8ggQ4NtSoxBPbZCDG5qAn0TyPm0Ajq4SX0781u90Ww2hizfMMwWJr1sGtbC1" 
                />
              </div>
              <div>
                <h2 className="text-xl font-extrabold">Eleanor Pena</h2>
                <p className="text-slate-500 text-sm font-medium">Customer ID: #RO-99281</p>
                <div className="mt-2 flex items-center gap-2">
                  <span className="px-2 py-0.5 rounded-full bg-green-100 text-green-600 text-xs font-bold uppercase tracking-wider">Active AMC</span>
                </div>
              </div>
            </div>
            <div className="size-16 p-1 bg-white border border-slate-200 rounded-lg shadow-inner flex items-center justify-center">
              <QrCode size={40} className="text-slate-800" />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 mb-6">
            <div className="p-3 bg-slate-50 rounded-lg border border-slate-100">
              <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Unit Model</p>
              <p className="text-sm font-semibold">Aquaguard RO+UV</p>
            </div>
            <div className="p-3 bg-slate-50 rounded-lg border border-slate-100">
              <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Installed On</p>
              <p className="text-sm font-semibold">Mar 12, 2022</p>
            </div>
          </div>

          <div className="flex gap-2">
            <button className="flex-1 bg-[#007fff] text-white py-2.5 rounded-lg font-bold text-sm flex items-center justify-center gap-2 shadow-lg shadow-[#007fff]/20 active:scale-95 transition-transform">
              <Phone size={18} /> Call
            </button>
            <button className="flex-1 bg-slate-100 text-slate-700 py-2.5 rounded-lg font-bold text-sm flex items-center justify-center gap-2 active:scale-95 transition-transform">
              <MapPin size={18} /> Locate
            </button>
            <button className="w-12 bg-slate-100 text-slate-700 rounded-lg flex items-center justify-center active:scale-95 transition-transform">
              <MessageCircle size={18} />
            </button>
          </div>
        </div>
      </section>

      <div className="px-4 sticky top-0 z-30 bg-[#f5f7f8]/95 py-2">
        <div className="bg-slate-200 p-1 rounded-xl flex">
          <button className="flex-1 bg-white py-2 rounded-lg text-sm font-bold shadow-sm transition-all text-slate-900">
            Service History
          </button>
          <button className="flex-1 py-2 rounded-lg text-sm font-bold text-slate-500 hover:text-slate-700 transition-all">
            Upcoming
          </button>
        </div>
      </div>

      <section className="px-4 mt-4 space-y-4 pb-32">
        <h3 className="text-xs font-black uppercase text-slate-400 tracking-widest px-1">Recent Visits</h3>
        
        {history.map((item, index) => (
          <motion.div
            key={item.id}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            className="bg-white rounded-xl border border-slate-100 overflow-hidden"
          >
            <div className="p-4 border-b border-slate-50 flex justify-between items-center">
              <div>
                <p className="text-sm font-extrabold">{item.title}</p>
                <p className="text-xs text-slate-500">{item.date}</p>
              </div>
              <span className="bg-[#007fff]/10 text-[#007fff] text-[10px] font-bold px-2 py-1 rounded">COMPLETED</span>
            </div>
            <div className="p-4 bg-slate-50/50">
              <p className="text-[10px] uppercase font-bold text-slate-400 mb-2">Parts Replaced</p>
              <div className="flex flex-wrap gap-2">
                {item.parts.map(part => (
                  <span key={part} className="bg-white border border-slate-200 px-2 py-1 rounded text-xs font-medium">{part}</span>
                ))}
              </div>
              <div className="mt-4 pt-4 border-t border-slate-100 flex justify-between items-center">
                <div className="flex items-center gap-2">
                  <div className="size-6 rounded-full bg-slate-200 overflow-hidden">
                    <img 
                      alt="Technician" 
                      className="w-full h-full object-cover" 
                      src="https://lh3.googleusercontent.com/aida-public/AB6AXuD4Sx1YCi58f2ilhJyNTxSaQFbgKcz_LvEdOFfhLLcWGGQpuwK2i1UO1Pf1R-91BdyKuR6oUASBI6C64cOVRUb0aua0pPcSYXFWMb2Y05px20SWNIIMlDyNq_1GySh9p1s_nv5NTPt1O2vZS_r74EIxHzIfyUuYuUr3J_Lrd6Us7MB_rIizokhySFMCrfJaGIRxtCGRm9U_grwST1htLPLIU19JqM7qTz_eUHiBgsjKemZWkOUWswtT3M1XOEWpgZ-3t9xH3-M_abF1" 
                    />
                  </div>
                  <p className="text-xs font-medium text-slate-600">Tech: {item.tech}</p>
                </div>
                <p className="text-sm font-bold text-[#007fff]">${item.price.toFixed(2)}</p>
              </div>
            </div>
          </motion.div>
        ))}
      </section>

      <div className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[430px] p-4 bg-gradient-to-t from-[#f5f7f8] via-[#f5f7f8]/95 to-transparent z-50">
        <button className="w-full bg-[#007fff] text-white py-4 rounded-xl font-extrabold text-base flex items-center justify-center gap-3 shadow-xl shadow-[#007fff]/30 active:scale-95 transition-all">
          <Calendar size={20} />
          Schedule New Service
        </button>
      </div>
    </div>
  );
};
