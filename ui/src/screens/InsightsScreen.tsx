import React from 'react';
import { TrendingUp, Timer, Share2, Info, ChevronRight, AlertTriangle, Clock, Calendar } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell, PieChart, Pie } from 'recharts';
import { motion } from 'motion/react';

export const InsightsScreen: React.FC = () => {
  const salesData = [
    { name: 'Mon', value: 40 },
    { name: 'Tue', value: 60 },
    { name: 'Wed', value: 55 },
    { name: 'Thu', value: 85 },
    { name: 'Fri', value: 100 },
    { name: 'Sat', value: 45 },
    { name: 'Sun', value: 30 },
  ];

  const serviceLoad = [
    { name: 'Alex Johnson', tasks: 42, color: '#007fff' },
    { name: 'Maria Garcia', tasks: 28, color: '#007fff99' },
    { name: 'Sam Wilson', tasks: 15, color: '#007fff4d' },
  ];

  const inventoryUsage = [
    { name: 'Sediment Filters', value: 65, color: '#007fff' },
    { name: 'RO Membranes', value: 25, color: '#007fff66' },
    { name: 'Others', value: 10, color: '#f1f5f9' },
  ];

  return (
    <div className="flex flex-col h-full bg-[#f5f7f8] pb-24">
      <div className="px-4 pt-4 overflow-x-auto no-scrollbar">
        <div className="flex gap-2 min-w-max pb-2">
          <button className="px-4 py-2 rounded-full text-sm font-bold bg-[#007fff] text-white shadow-md">Today</button>
          <button className="px-4 py-2 rounded-full text-sm font-bold bg-white text-slate-500 border border-slate-200">This Week</button>
          <button className="px-4 py-2 rounded-full text-sm font-bold bg-white text-slate-500 border border-slate-200">This Month</button>
          <button className="px-4 py-2 rounded-full text-sm font-bold bg-white text-slate-500 border border-slate-200 flex items-center gap-1">
            <Calendar size={14} />
            Custom
          </button>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 px-4 py-4">
        <div className="flex flex-col gap-1 rounded-xl bg-white p-4 border border-slate-100 shadow-sm">
          <div className="flex items-center justify-between">
            <p className="text-slate-500 text-xs font-semibold uppercase tracking-wider">Revenue</p>
            <TrendingUp className="text-green-500" size={18} />
          </div>
          <p className="text-2xl font-extrabold">$14,290</p>
          <p className="text-green-500 text-xs font-bold">+12.4% vs prev.</p>
        </div>
        <div className="flex flex-col gap-1 rounded-xl bg-white p-4 border border-slate-100 shadow-sm">
          <div className="flex items-center justify-between">
            <p className="text-slate-500 text-xs font-semibold uppercase tracking-wider">Avg TAT</p>
            <Timer className="text-[#007fff]" size={18} />
          </div>
          <p className="text-2xl font-extrabold">3.8 hrs</p>
          <p className="text-[#007fff] text-xs font-bold">-15% improvement</p>
        </div>
      </div>

      <section className="px-4 mb-6">
        <div className="rounded-xl bg-white p-5 border border-slate-100 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="text-lg font-bold">Sales Trends</h2>
              <p className="text-xs text-slate-500">Revenue growth over the last 7 days</p>
            </div>
            <Info className="text-slate-400" size={18} />
          </div>
          
          <div className="h-40 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={salesData}>
                <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                  {salesData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.name === 'Fri' ? '#007fff' : '#007fff40'} />
                  ))}
                </Bar>
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 10, fontWeight: 'bold', fill: '#94a3b8' }} />
                <Tooltip cursor={{ fill: 'transparent' }} content={() => null} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </section>

      <div className="grid grid-cols-1 gap-6 px-4 mb-8">
        <section className="rounded-xl bg-white p-5 border border-slate-100 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-bold">Service Load</h2>
            <select className="text-xs bg-slate-50 border-none rounded-lg font-bold text-[#007fff] focus:ring-0">
              <option>By Technician</option>
              <option>By Region</option>
            </select>
          </div>
          <div className="space-y-4">
            {serviceLoad.map(tech => (
              <div key={tech.name} className="space-y-1">
                <div className="flex justify-between text-xs font-bold mb-1">
                  <span>{tech.name}</span>
                  <span>{tech.tasks} Tasks</span>
                </div>
                <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
                  <motion.div 
                    initial={{ width: 0 }}
                    animate={{ width: `${(tech.tasks / 50) * 100}%` }}
                    className="bg-[#007fff] h-full rounded-full"
                  />
                </div>
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-xl bg-white p-5 border border-slate-100 shadow-sm">
          <h2 className="text-lg font-bold mb-4">Inventory Usage</h2>
          <div className="flex items-center gap-6">
            <div className="relative flex items-center justify-center size-28 shrink-0">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={inventoryUsage}
                    cx="50%"
                    cy="50%"
                    innerRadius={35}
                    outerRadius={45}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {inventoryUsage.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div className="absolute flex flex-col items-center">
                <span className="text-xl font-extrabold">142</span>
                <span className="text-[10px] text-slate-400 font-bold uppercase">Units</span>
              </div>
            </div>
            <div className="flex-1 space-y-2">
              {inventoryUsage.map(item => (
                <div key={item.name} className="flex items-center gap-2">
                  <div className="size-3 rounded-full" style={{ backgroundColor: item.color }}></div>
                  <span className="text-xs font-semibold">{item.name} ({item.value}%)</span>
                </div>
              ))}
            </div>
          </div>
        </section>
      </div>

      <div className="px-4 mb-8">
        <h3 className="text-sm font-bold text-slate-500 uppercase tracking-widest mb-3">Critical Alerts</h3>
        <div className="space-y-3">
          <div className="flex items-center gap-3 p-3 bg-red-50 border border-red-100 rounded-xl">
            <div className="size-10 rounded-lg bg-red-100 flex items-center justify-center text-red-600">
              <AlertTriangle size={20} />
            </div>
            <div className="flex-1">
              <p className="text-sm font-bold text-red-900">Low Stock: Pre-filter</p>
              <p className="text-xs text-red-700">Only 5 units remaining in main hub.</p>
            </div>
            <ChevronRight className="text-red-300" size={18} />
          </div>
          <div className="flex items-center gap-3 p-3 bg-[#007fff]/5 border border-[#007fff]/10 rounded-xl">
            <div className="size-10 rounded-lg bg-[#007fff]/10 flex items-center justify-center text-[#007fff]">
              <Clock size={20} />
            </div>
            <div className="flex-1">
              <p className="text-sm font-bold text-slate-900">SLA Breach Risk</p>
              <p className="text-xs text-slate-500">3 services in Downtown are pending &gt; 24hrs.</p>
            </div>
            <ChevronRight className="text-slate-300" size={18} />
          </div>
        </div>
      </div>
    </div>
  );
};
