import React from 'react';
import { LogIn, Mail, Lock, Eye, Droplets } from 'lucide-react';

interface LoginScreenProps {
  onLogin: () => void;
}

export const LoginScreen: React.FC<LoginScreenProps> = ({ onLogin }) => {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-6 bg-[#f5f7f8]">
      <div className="w-full max-w-[400px] flex flex-col">
        <div className="flex flex-col items-center mb-10">
          <div className="w-20 h-20 bg-[#007fff]/10 rounded-2xl flex items-center justify-center mb-6">
            <span className="material-symbols-outlined text-[#007fff] text-5xl">water_drop</span>
          </div>
          <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 mb-2">Welcome Back</h1>
          <p className="text-slate-500 text-center text-sm leading-relaxed max-w-[280px]">
            Enter your credentials to manage inventory and services.
          </p>
        </div>

        <form className="space-y-5" onSubmit={(e) => { e.preventDefault(); onLogin(); }}>
          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-slate-700 ml-1">Email Address</label>
            <div className="relative group">
              <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <Mail className="text-slate-400 group-focus-within:text-[#007fff] transition-colors" size={20} />
              </div>
              <input 
                className="block w-full h-14 pl-12 pr-4 bg-white border border-slate-200 rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#007fff]/20 focus:border-[#007fff] transition-all text-base" 
                placeholder="name@company.com" 
                type="email"
                defaultValue="admin@roservice.com"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-semibold text-slate-700 ml-1">Password</label>
            <div className="relative group">
              <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <Lock className="text-slate-400 group-focus-within:text-[#007fff] transition-colors" size={20} />
              </div>
              <input 
                className="block w-full h-14 pl-12 pr-12 bg-white border border-slate-200 rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#007fff]/20 focus:border-[#007fff] transition-all text-base" 
                placeholder="••••••••" 
                type="password"
                defaultValue="password123"
              />
              <button className="absolute inset-y-0 right-0 pr-4 flex items-center" type="button">
                <Eye className="text-slate-400 hover:text-slate-600 transition-colors" size={20} />
              </button>
            </div>
            <div className="flex justify-end mt-1">
              <a className="text-xs font-bold text-[#007fff] hover:text-[#007fff]/80 transition-colors" href="#">Forgot Password?</a>
            </div>
          </div>

          <button 
            className="w-full h-14 bg-[#007fff] hover:bg-[#007fff]/90 active:scale-[0.98] text-white font-bold rounded-xl shadow-lg shadow-[#007fff]/20 transition-all flex items-center justify-center gap-2 mt-4" 
            type="submit"
          >
            <span>Login</span>
            <LogIn size={20} />
          </button>
        </form>

        <div className="mt-auto pt-12 text-center">
          <p className="text-sm text-slate-500">
            Don't have access? 
            <a className="text-[#007fff] font-bold hover:underline ml-1" href="#">Contact Administrator</a>
          </p>
        </div>
      </div>
    </div>
  );
};
