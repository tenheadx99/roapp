import React, { useState } from 'react';
import { Calendar, Clock, MapPin, Droplets, Wrench, Send, X, ChevronDown } from 'lucide-react';
import { SERVICE_REQUESTS } from '../constants';
import { motion } from 'motion/react';

export const DispatchHubScreen: React.FC = () => {
  const [activeTab, setActiveTab] = useState('New (4)');
  const [showAssignPanel, setShowAssignPanel] = useState(false);

  const tabs = ['New (4)', 'Assigned (12)', 'In Progress (8)'];
  const days = [
    { day: 'Mon', date: '02' },
    { day: 'Tue', date: '03' },
    { day: 'Wed', date: '04' },
    { day: 'Thu', date: '05', active: true },
    { day: 'Fri', date: '06' },
    { day: 'Sat', date: '07' },
    { day: 'Sun', date: '08' },
  ];

  return (
    <div className="flex flex-col h-full relative">
      <div className="bg-white py-4 border-b border-slate-200">
        <div className="flex items-center justify-between px-4 mb-3">
          <h2 className="text-sm font-bold uppercase tracking-wider text-slate-500">October 2023</h2>
          <button className="text-[#007fff] text-sm font-semibold flex items-center gap-1">
            Full Calendar <Calendar size={14} />
          </button>
        </div>
        <div className="flex overflow-x-auto hide-scrollbar px-4 gap-3">
          {days.map(d => (
            <div 
              key={d.date}
              className={`flex flex-col items-center min-w-[50px] py-2 rounded-xl border transition-all ${
                d.active 
                  ? 'bg-[#007fff] border-[#007fff] shadow-lg shadow-[#007fff]/30' 
                  : 'bg-slate-50 border-slate-100'
              }`}
            >
              <span className={`text-[10px] font-bold uppercase ${d.active ? 'text-white/80' : 'text-slate-400'}`}>{d.day}</span>
              <span className={`text-base font-bold ${d.active ? 'text-white' : 'text-slate-900'}`}>{d.date}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="bg-white px-4 py-3 flex gap-2 overflow-x-auto hide-scrollbar">
        {tabs.map(tab => (
          <button 
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-5 py-2 rounded-full text-sm font-bold whitespace-nowrap transition-colors ${
              activeTab === tab ? 'bg-[#007fff] text-white' : 'bg-slate-100 text-slate-600'
            }`}
          >
            {tab}
          </button>
        ))}
      </div>

      <main className="flex-1 overflow-y-auto px-4 py-4 space-y-4 pb-32">
        <h3 className="text-base font-bold text-slate-800">Pending Requests</h3>
        
        {SERVICE_REQUESTS.map((req, index) => (
          <motion.div
            key={req.id}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm"
          >
            <div className="p-4">
              <div className="flex justify-between items-start mb-2">
                <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-[#007fff]/10 text-[#007fff] border border-[#007fff]/20 uppercase tracking-wider">NEW</span>
                <span className="text-xs text-slate-400 flex items-center gap-1">
                  <Clock size={12} /> {req.time}
                </span>
              </div>
              <h4 className="font-bold text-lg mb-1">{req.customerName}</h4>
              <p className="text-xs text-slate-500 mb-3 flex items-center gap-1">
                <MapPin size={14} /> {req.address}
              </p>
              <div className="flex items-center justify-between pt-3 border-t border-slate-100">
                <div className="flex items-center gap-2">
                  <div className="size-8 rounded-lg bg-slate-100 flex items-center justify-center">
                    {req.type.includes('Filter') ? <Droplets className="text-[#007fff]" size={18} /> : <Wrench className="text-[#007fff]" size={18} />}
                  </div>
                  <div>
                    <p className="text-xs font-bold">{req.type}</p>
                    <p className="text-[10px] text-slate-400">{req.model}</p>
                  </div>
                </div>
                <button 
                  onClick={() => setShowAssignPanel(true)}
                  className="bg-[#007fff] hover:bg-[#007fff]/90 text-white text-xs font-bold px-4 py-2 rounded-lg transition-colors"
                >
                  Assign
                </button>
              </div>
            </div>
          </motion.div>
        ))}
      </main>

      {showAssignPanel && (
        <>
          <div className="fixed inset-0 bg-black/20 z-40" onClick={() => setShowAssignPanel(false)} />
          <motion.div 
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            className="fixed inset-x-0 bottom-0 z-50 bg-white rounded-t-[2rem] shadow-[0_-10px_40px_rgba(0,0,0,0.1)] border-t border-slate-100"
          >
            <div className="flex flex-col p-6 space-y-4">
              <div className="w-12 h-1.5 bg-slate-200 rounded-full mx-auto mb-2"></div>
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-lg font-bold">Assign Technician</h4>
                <button 
                  onClick={() => setShowAssignPanel(false)}
                  className="size-8 rounded-full bg-slate-100 flex items-center justify-center"
                >
                  <X size={16} />
                </button>
              </div>
              
              <div className="space-y-1.5">
                <label className="text-[10px] font-bold uppercase text-slate-400 tracking-wider">Select Staff</label>
                <div className="relative">
                  <select className="w-full h-12 bg-slate-50 border-none rounded-xl px-4 text-sm font-medium focus:ring-2 focus:ring-[#007fff] appearance-none">
                    <option>Choose Technician...</option>
                    <option>Michael Scott (Available)</option>
                    <option>Dwight Schrute (Busy)</option>
                    <option>Jim Halpert (Available)</option>
                  </select>
                  <ChevronDown className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" size={18} />
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="text-[10px] font-bold uppercase text-slate-400 tracking-wider">Service Notes</label>
                <textarea 
                  className="w-full bg-slate-50 border-none rounded-xl p-4 text-sm font-medium focus:ring-2 focus:ring-[#007fff]" 
                  placeholder="e.g. Gate code 1234, Check TDS levels specifically..." 
                  rows={2}
                />
              </div>

              <button 
                onClick={() => setShowAssignPanel(false)}
                className="w-full bg-[#007fff] text-white h-14 rounded-2xl font-bold flex items-center justify-center gap-2 shadow-lg shadow-[#007fff]/25 active:scale-95 transition-transform"
              >
                Confirm Assignment
                <Send size={18} />
              </button>
            </div>
          </motion.div>
        </>
      )}
    </div>
  );
};
