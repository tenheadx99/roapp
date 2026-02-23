import React from 'react';
import { Bell, Wrench, Package, AlertTriangle, CheckCircle, UserPlus, Calendar, ChevronRight, Truck } from 'lucide-react';
import { motion } from 'motion/react';

export const NotificationsScreen: React.FC = () => {
  return (
    <div className="flex flex-col h-full">
      <div className="px-4 pb-4 bg-white border-b border-slate-100">
        <div className="flex p-1 bg-slate-200 rounded-xl">
          <button className="flex-1 py-1.5 text-sm font-semibold rounded-lg bg-white shadow-sm text-slate-900">All</button>
          <button className="flex-1 py-1.5 text-sm font-medium text-slate-500">Inventory</button>
          <button className="flex-1 py-1.5 text-sm font-medium text-slate-500">Service</button>
        </div>
      </div>

      <main className="flex-1 overflow-y-auto pb-24">
        <section className="mt-4">
          <div className="px-4 mb-2 flex items-center justify-between">
            <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500">Urgent Alerts</h2>
            <span className="bg-red-500 text-white text-[10px] px-1.5 py-0.5 rounded-full font-bold">2 NEW</span>
          </div>

          <motion.div 
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            className="mx-4 mb-3 p-4 bg-white rounded-xl shadow-sm border-l-4 border-red-500 relative overflow-hidden"
          >
            <div className="flex gap-4">
              <div className="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center shrink-0">
                <Package className="text-red-600" size={24} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex justify-between items-start">
                  <h3 className="font-bold text-slate-900 truncate">Critical: Low Stock</h3>
                  <span className="text-[11px] font-medium text-slate-400">2m ago</span>
                </div>
                <p className="text-sm text-slate-600 mt-0.5 leading-relaxed">RO Filter Membrane stock is below 10 units. Reorder required immediately to avoid service delays.</p>
                <div className="mt-3 flex gap-2">
                  <button className="px-4 py-1.5 bg-red-500 text-white text-xs font-bold rounded-lg">Order Now</button>
                  <button className="px-4 py-1.5 bg-slate-100 text-slate-600 text-xs font-bold rounded-lg">Dismiss</button>
                </div>
              </div>
            </div>
          </motion.div>

          <motion.div 
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.1 }}
            className="mx-4 mb-3 p-4 bg-white rounded-xl shadow-sm border-l-4 border-red-500"
          >
            <div className="flex gap-4">
              <div className="w-12 h-12 rounded-full bg-orange-100 flex items-center justify-center shrink-0">
                <AlertTriangle className="text-orange-600" size={24} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex justify-between items-start">
                  <h3 className="font-bold text-slate-900 truncate">Overdue Maintenance</h3>
                  <span className="text-[11px] font-medium text-slate-400">1h ago</span>
                </div>
                <p className="text-sm text-slate-600 mt-0.5 leading-relaxed">AMC for Mr. Sharma (ID: #4402) was due yesterday. No technician assigned yet.</p>
                <div className="mt-3 flex gap-2">
                  <button className="px-4 py-1.5 bg-[#007fff] text-white text-xs font-bold rounded-lg">Assign Tech</button>
                  <button className="px-4 py-1.5 bg-slate-100 text-slate-600 text-xs font-bold rounded-lg">Mark Read</button>
                </div>
              </div>
            </div>
          </motion.div>
        </section>

        <section className="mt-6">
          <div className="px-4 mb-2">
            <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500">Recently Received</h2>
          </div>

          <div className="bg-white border-b border-slate-100 px-4 py-4 flex gap-4 items-start">
            <div className="w-10 h-10 rounded-full bg-[#007fff]/10 flex items-center justify-center shrink-0">
              <Wrench className="text-[#007fff]" size={20} />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex justify-between items-center">
                <h3 className="font-semibold text-slate-900 text-[15px]">New Service Request</h3>
                <span className="text-[11px] text-slate-400">3h ago</span>
              </div>
              <p className="text-sm text-slate-500 mt-0.5">Customer requested a TDS check at Sector 45, Green Villa.</p>
            </div>
            <div className="flex items-center self-center pl-2">
              <div className="w-2 h-2 rounded-full bg-[#007fff]"></div>
            </div>
          </div>

          <div className="bg-white border-b border-slate-100 px-4 py-4 flex gap-4 items-start opacity-70">
            <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center shrink-0">
              <Truck className="text-slate-500" size={20} />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex justify-between items-center">
                <h3 className="font-semibold text-slate-900 text-[15px]">Stock Delivered</h3>
                <span className="text-[11px] text-slate-400">5h ago</span>
              </div>
              <p className="text-sm text-slate-500 mt-0.5">Consignment #INV-9021 (Sediment Filters) has been received at Main Hub.</p>
            </div>
          </div>
        </section>

        <div className="mt-8 px-4 text-center">
          <button className="text-slate-400 text-sm font-medium hover:text-[#007fff] transition-colors">View Notification Archive</button>
        </div>
      </main>
    </div>
  );
};
