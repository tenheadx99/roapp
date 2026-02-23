import { Customer, InventoryItem, Supplier, Technician, ServiceRequest } from './types';

export const CUSTOMERS: Customer[] = [
  { id: '1', name: 'Arjun Sharma', phone: '+91 98765 43210', model: 'Kent Grand+ RO (12L)', status: 'Service Due', lastService: '15 Oct 2023', area: 'West Delhi' },
  { id: '2', name: 'Priya Mehra', phone: '+91 88223 11445', model: 'Pureit Copper+ Mineral', status: 'Operational', lastService: '02 Jan 2024', area: 'Rohini' },
  { id: '3', name: 'Vikram Singh', phone: '+91 70012 33490', model: 'Aquaguard Ritz RO+UV', status: 'AMC Plan', lastService: '18 Dec 2023', area: 'West Delhi' },
  { id: '4', name: 'Sneha Kapoor', phone: '+91 99112 22334', model: 'Livpure Bolt (RO+UF)', status: 'Pending Install', lastService: 'New Customer', area: 'Rohini' },
];

export const INVENTORY: InventoryItem[] = [
  { id: '1', name: 'RO Membrane 75 GPD', sku: 'RO-MEM-75', supplier: 'Aquaflow', price: 24.00, stock: 4, lowStockThreshold: 10, category: 'Membranes' },
  { id: '2', name: 'Sediment Filter 5 Micron', sku: 'SF-5M-01', supplier: 'PureWater Corp', price: 8.50, stock: 42, lowStockThreshold: 10, category: 'Filters' },
  { id: '3', name: 'Booster Pump 100 GPD', sku: 'BP-100G', supplier: 'PowerFlow', price: 45.00, stock: 12, lowStockThreshold: 5, category: 'Pumps' },
  { id: '4', name: 'Activated Carbon Block', sku: 'AC-BLK-09', supplier: 'PureWater Corp', price: 12.00, stock: 2, lowStockThreshold: 10, category: 'Filters' },
  { id: '5', name: 'TDS Controller Valve', sku: 'VAL-TDS-V', supplier: 'Aquaflow', price: 5.50, stock: 85, lowStockThreshold: 20, category: 'Filters' },
];

export const SUPPLIERS: Supplier[] = [
  { id: '1', name: 'AquaTech Solutions', contactPerson: 'Rajesh Kumar', city: 'New Delhi', specialties: ['Dow Membranes', 'Booster Pumps'], activePOs: 8, status: 'active' },
  { id: '2', name: 'PureFlow Filtration Ltd.', contactPerson: 'Amit Shah', city: 'Mumbai', specialties: ['Sediment Filters', 'Pre-Filters'], activePOs: 3, status: 'active' },
  { id: '3', name: 'Z-Electron Components', contactPerson: 'Vikram Singh', city: 'Bengaluru', specialties: ['SMPS Adapters', 'Solenoid Valves'], activePOs: 0, status: 'inactive' },
];

export const TECHNICIANS: Technician[] = [
  { id: '1', name: 'Marcus Wright', phone: '+1 (555) 012-3456', region: 'North District', hubs: ['Service Hub A'], tasksToday: 4, status: 'online', avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA9lswdW5QGSMSMk1aXc8ju9jp2gwQBmxHFjfumiZa1PoNSjb4SXKFFZnLtqavWmnpiJl3KOsf76sI7idoyiPWjO4MZi07rM2s48qVv9OlF-urYfKkaNBoTh4M1aJjDmLD6u0j4thUEPJeyWZx_ScKEBy-0re3Bwk9jjTsiObdUumdZWQAwUBMSmO3VrFVo9oLlDVyzIEI6KJbL6woeAyiRfdTS16TrGMh1UGTtjjwNjR8sizFaQddudIyNxskKYP7OFLUq0NsaZ9eK' },
  { id: '2', name: 'Sarah Jenkins', phone: '+1 (555) 098-7654', region: 'Downtown', hubs: [], tasksToday: 2, status: 'online', avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBnwJopyyh8AxehBtHYpnVo76uiqYpRrd-bErBG9eBhFH8w1P_UvlA4704uvrA-pNqcSQXlAuGWrcm4zuPmECsBpzERZLoYGIrvD3sMVGOwwOWZBq21P8Uk40-OE72BiJHnZFm8ajfjozgjI4bMZ4i2pi-34mJZVGxQrZ2QCBTh6IYfaRhewfnJqQxEvM3tFA2Y4nPm43zqSBlLVCphwUM9I1z-7QZV9rtMu8FBOSRgbJwFHZudMzB2uhBKU6jtvsdJFpWiMngBJZSy' },
  { id: '3', name: 'James D.', phone: '+1 (555) 234-5678', region: 'Industrial Park', hubs: [], tasksToday: 0, status: 'on-leave', avatar: '' },
  { id: '4', name: 'Arjun Mehta', phone: '+1 (555) 765-4321', region: 'East Zone', hubs: ['RO Specialist'], tasksToday: 6, status: 'online', avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDFGmsO7VFib-HJRtUy9iPiZt_Vw9d1XTapb2DIJlf87sLFSA5MYYfQTL_Z2kSHTzDDOpXvruGtto2gfZZSFEYAvr9vRVR3Tl5A9iZVFR2WB3PYMrbrWZcU0toXMDUkVs05FsK4ffTXpQtjyE4M-NfIIgVkWZCNu8ZQzrhPDxEdXXfF24A1muH4W7CXqy28ISIbOkPvwAbD7v7lJp1kwb_FKMCa0he-Grwze6k0uLfsvyAvzEV3pdMyTbgpWDLrR3D51bbOArP_JRTB' },
];

export const SERVICE_REQUESTS: ServiceRequest[] = [
  { id: '1', customerName: 'John Doe', address: 'Apartment 4B, Emerald Heights', type: 'Filter Replacement', model: 'RO Pure-X Model 2023', time: '10:30 AM', status: 'new' },
  { id: '2', customerName: 'Sarah Jenkins', address: '124 Oak Drive, Northwood', type: 'Leaking Component', model: 'Aqua-Flow Plus', time: '01:15 PM', status: 'new' },
];
