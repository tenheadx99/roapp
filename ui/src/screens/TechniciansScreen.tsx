import React from 'react';
import { Search, UserPlus, Phone, MessageCircle, Calendar, Edit2 } from 'lucide-react';
import { TECHNICIANS } from '../constants';
import { motion } from 'motion/react';

export const TechniciansScreen: React.FC = () => {
  return (
    <div className="flex flex-col h-full">
      <div className="px-5 pt-4 pb-4 bg-white/80 backdrop-blur-md sticky top-0 z-10">
        <div className="flex items-center justify-between mb-4">
          <div>
            <p className="text-sm font-medium text-slate-500">12 Active Team Members</p>
          </div>
          <button className="bg-[#007fff] hover:bg-[#007fff]/90 text-white p-2.5 rounded-full shadow-lg shadow-[#007fff]/20 flex items-center justify-center transition-all active:scale-95">
            <UserPlus size={24} />
          </button>
        </div>

        <div className="relative group">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-[#007fff] transition-colors" size={18} />
          <input 
            className="w-full bg-slate-200/50 border-none rounded-xl py-3 pl-10 pr-4 text-sm focus:ring-2 focus:ring-[#007fff]/50 transition-all placeholder:text-slate-500" 
            placeholder="Search name or region..." 
            type="text"
          />
        </div>

        <div className="flex gap-2 overflow-x-auto no-scrollbar mt-4 pb-1">
          <button className="flex-none px-4 py-1.5 rounded-full bg-[#007fff] text-white text-xs font-semibold">All</button>
          <button className="flex-none px-4 py-1.5 rounded-full bg-white text-slate-600 text-xs font-semibold border border-slate-200">North District</button>
          <button className="flex-none px-4 py-1.5 rounded-full bg-white text-slate-600 text-xs font-semibold border border-slate-200">Downtown</button>
          <button className="flex-none px-4 py-1.5 rounded-full bg-white text-slate-600 text-xs font-semibold border border-slate-200">Industrial Park</button>
        </div>
      </div>

      <main className="flex-1 px-5 py-4 space-y-4 overflow-y-auto pb-24">
        {TECHNICIANS.map((tech, index) => (
          <motion.div
            key={tech.id}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.05 }}
            className="bg-white rounded-xl p-4 border border-slate-100 shadow-sm"
          >
            <div className="flex items-start gap-3">
              <div className="relative">
                {tech.avatar ? (
                  <img 
                    alt={tech.name} 
                    className="size-14 rounded-full object-cover border-2 border-slate-50" 
                    src={tech.avatar} 
                  />
                ) : (
                  <div className="size-14 rounded-full bg-slate-200 flex items-center justify-center border-2 border-slate-50 text-slate-500 font-bold">
                    {tech.name.split(' ').map(n => n[0]).join('')}
                  </div>
                )}
                <span className={`absolute bottom-0 right-0 size-3.5 border-2 border-white rounded-full ${
                  tech.status === 'online' ? 'bg-green-500' : 
                  tech.status === 'on-leave' ? 'bg-slate-400' : 'bg-red-500'
                }`}></span>
              </div>
              <div className="flex-1">
                <div className="flex items-center justify-between">
                  <h3 className="font-bold text-slate-900">
                    {tech.name}
                    {tech.status === 'on-leave' && <span className="text-xs font-normal text-slate-400 ml-1">(On Leave)</span>}
                  </h3>
                  <div className="flex gap-2">
                    <button className="text-[#007fff] hover:bg-[#007fff]/10 p-1 rounded-lg transition-colors">
                      <Phone size={18} />
                    </button>
                    <button className="text-[#007fff] hover:bg-[#007fff]/10 p-1 rounded-lg transition-colors">
                      <MessageCircle size={18} />
                    </button>
                  </div>
                </div>
                <p className="text-xs font-medium text-slate-500">{tech.phone}</p>
                <div className="mt-3 flex flex-wrap gap-1.5">
                  <span className="bg-[#007fff]/10 text-[#007fff] text-[10px] font-bold px-2 py-0.5 rounded uppercase tracking-wider">{tech.region}</span>
                  {tech.hubs.map(hub => (
                    <span key={hub} className="bg-[#007fff]/10 text-[#007fff] text-[10px] font-bold px-2 py-0.5 rounded uppercase tracking-wider">{hub}</span>
                  ))}
                </div>
              </div>
            </div>
            <div className="mt-4 pt-4 border-t border-slate-50 flex items-center justify-between">
              <div className="flex items-center gap-1 text-xs text-slate-500">
                <Calendar size={14} />
                <span>{tech.tasksToday > 0 ? `${tech.tasksToday} Tasks Today` : tech.status === 'on-leave' ? 'Next available: Mon' : 'No tasks today'}</span>
              </div>
              <div className="flex gap-3">
                <button className="text-[#007fff] text-sm font-bold px-2 py-1 hover:bg-[#007fff]/5 rounded">View Schedule</button>
                <button className="text-slate-400 text-sm font-bold px-2 py-1 hover:bg-slate-100 rounded">Edit Profile</button>
              </div>
            </div>
          </motion.div>
        ))}
      </main>
    </div>
  );
};
