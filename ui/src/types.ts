export type Screen = 
  | 'login' 
  | 'dashboard' 
  | 'customers' 
  | 'customer-profile' 
  | 'inventory' 
  | 'suppliers' 
  | 'dispatch' 
  | 'insights' 
  | 'notifications' 
  | 'technicians';

export interface Customer {
  id: string;
  name: string;
  phone: string;
  model: string;
  status: 'Service Due' | 'Operational' | 'AMC Plan' | 'Pending Install';
  lastService: string;
  area: string;
}

export interface InventoryItem {
  id: string;
  name: string;
  sku: string;
  supplier: string;
  price: number;
  stock: number;
  lowStockThreshold: number;
  category: string;
}

export interface Supplier {
  id: string;
  name: string;
  contactPerson: string;
  city: string;
  specialties: string[];
  activePOs: number;
  status: 'active' | 'inactive';
}

export interface Technician {
  id: string;
  name: string;
  phone: string;
  region: string;
  hubs: string[];
  tasksToday: number;
  status: 'online' | 'offline' | 'on-leave';
  avatar: string;
}

export interface ServiceRequest {
  id: string;
  customerName: string;
  address: string;
  type: string;
  model: string;
  time: string;
  status: 'new' | 'assigned' | 'in-progress';
}
