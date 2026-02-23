import React from 'react';
import { TrendingUp, TrendingDown, Package, Wrench, Users, AlertTriangle, CheckCircle, UserPlus, Calendar } from 'lucide-react';
import { motion } from 'motion/react';

export const DashboardScreen: React.FC = () => {
  const stats = [
    { label: 'Total Inventory', value: '142', trend: '+5%', trendType: 'up', icon: Package, color: 'blue' },
    { label: 'Pending Service', value: '12', trend: '+2%', trendType: 'up', icon: Wrench, color: 'primary' },
    { label: 'Total Customers', value: '850', trend: '-1%', trendType: 'down', icon: Users, color: 'slate' },
    { label: 'Low Stock', value: '3', trend: 'Alert', trendType: 'alert', icon: AlertTriangle, color: 'red' },
  ];

  const activities = [
    { id: 1, title: 'Service Completed', desc: 'RO Maintenance: John Doe', time: '2 mins ago', icon: CheckCircle, color: 'green' },
    { id: 2, title: 'New Customer', desc: 'Riverside Apt • Block B-402', time: '1 hour ago', icon: UserPlus, color: 'blue' },
    { id: 3, title: 'Maintenance Scheduled', desc: 'Filter Change: Sarah Smith', time: '3 hours ago', icon: Calendar, color: 'orange' },
  ];

  return (
    <div className="px-4 pt-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-base font-bold text-slate-900">Business Overview</h3>
        <span className="text-xs font-semibold text-[#007fff] bg-[#007fff]/10 px-2 py-1 rounded-full uppercase tracking-wider">Today</span>
      </div>

      <div className="grid grid-cols-2 gap-4">
        {stats.map((stat, index) => (
          <motion.div
            key={stat.label}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            className="flex flex-col gap-2 rounded-xl bg-white p-5 shadow-sm border border-slate-100"
          >
            <div className="flex items-center justify-between">
              <div className={`p-2 rounded-lg ${
                stat.color === 'blue' ? 'bg-blue-50 text-blue-600' :
                stat.color === 'red' ? 'bg-red-50 text-red-600' :
                stat.color === 'primary' ? 'bg-[#007fff]/10 text-[#007fff]' :
                'bg-slate-50 text-slate-600'
              }`}>
                <stat.icon size={24} />
              </div>
              <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded flex items-center gap-0.5 ${
                stat.trendType === 'up' ? 'text-green-500 bg-green-50' :
                stat.trendType === 'down' ? 'text-red-500 bg-red-50' :
                'text-slate-500 bg-slate-100'
              }`}>
                {stat.trendType === 'up' && <TrendingUp size={12} />}
                {stat.trendType === 'down' && <TrendingDown size={12} />}
                {stat.trend}
              </span>
            </div>
            <div>
              <p className="text-slate-500 text-xs font-medium leading-normal">{stat.label}</p>
              <p className={`text-2xl font-extrabold leading-tight ${stat.color === 'red' ? 'text-red-600' : 'text-slate-900'}`}>{stat.value}</p>
            </div>
          </motion.div>
        ))}
      </div>

      <div className="mt-8">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-base font-bold text-slate-900">Recent Activity</h3>
          <button className="text-sm font-semibold text-[#007fff]">View All</button>
        </div>
        <div className="space-y-0 relative">
          {activities.map((activity, index) => (
            <div key={activity.id} className="grid grid-cols-[48px_1fr] gap-x-2">
              <div className="flex flex-col items-center">
                <div className={`z-10 flex size-10 items-center justify-center rounded-full shadow-sm border ${
                  activity.color === 'green' ? 'bg-green-50 text-green-600 border-green-100' :
                  activity.color === 'blue' ? 'bg-blue-50 text-blue-600 border-blue-100' :
                  'bg-orange-50 text-orange-600 border-orange-100'
                }`}>
                  <activity.icon size={20} />
                </div>
                {index < activities.length - 1 && (
                  <div className="w-[2px] bg-slate-200 grow"></div>
                )}
              </div>
              <div className="flex flex-1 flex-col pb-6 pt-1">
                <p className="text-slate-900 text-sm font-semibold leading-normal">{activity.title}</p>
                <p className="text-slate-500 text-sm font-normal">{activity.desc}</p>
                <p className="text-[#007fff] text-[11px] font-bold mt-1">{activity.time}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      <button className="fixed bottom-24 right-4 size-14 rounded-full bg-[#007fff] text-white shadow-lg shadow-[#007fff]/30 flex items-center justify-center z-20 active:scale-90 transition-transform">
        <span className="material-symbols-outlined text-3xl">add</span>
      </button>
    </div>
  );
};
