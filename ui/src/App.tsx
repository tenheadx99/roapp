/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { useState, useEffect } from 'react';
import { Screen } from './types';
import { Layout } from './components/Layout';
import { LoginScreen } from './screens/LoginScreen';
import { DashboardScreen } from './screens/DashboardScreen';
import { CustomerListScreen } from './screens/CustomerListScreen';
import { CustomerProfileScreen } from './screens/CustomerProfileScreen';
import { InventoryScreen } from './screens/InventoryScreen';
import { SupplierDirectoryScreen } from './screens/SupplierDirectoryScreen';
import { DispatchHubScreen } from './screens/DispatchHubScreen';
import { NotificationsScreen } from './screens/NotificationsScreen';
import { TechniciansScreen } from './screens/TechniciansScreen';
import { InsightsScreen } from './screens/InsightsScreen';
import { motion, AnimatePresence } from 'motion/react';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('login');
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  const handleLogin = () => {
    setIsLoggedIn(true);
    setCurrentScreen('dashboard');
  };

  const getTitle = () => {
    switch (currentScreen) {
      case 'dashboard': return 'Business Overview';
      case 'customers': return 'Customer Database';
      case 'customer-profile': return 'Customer Profile';
      case 'inventory': return 'Parts & Filters';
      case 'suppliers': return 'Supplier Directory';
      case 'dispatch': return 'Dispatch Hub';
      case 'insights': return 'Insights';
      case 'notifications': return 'Notifications';
      case 'technicians': return 'Technicians';
      default: return 'RO Manager';
    }
  };

  const renderScreen = () => {
    switch (currentScreen) {
      case 'login':
        return <LoginScreen onLogin={handleLogin} />;
      case 'dashboard':
        return <DashboardScreen />;
      case 'customers':
        return <CustomerListScreen onSelectCustomer={() => setCurrentScreen('customer-profile')} />;
      case 'customer-profile':
        return <CustomerProfileScreen />;
      case 'inventory':
        return <InventoryScreen onNavigateToSuppliers={() => setCurrentScreen('suppliers')} />;
      case 'suppliers':
        return <SupplierDirectoryScreen />;
      case 'dispatch':
        return <DispatchHubScreen />;
      case 'insights':
        return <InsightsScreen />;
      case 'technicians':
        return <TechniciansScreen />;
      case 'settings':
        return <div className="p-4">Settings Screen (Coming soon)</div>;
      case 'notifications':
        return <NotificationsScreen />;
      default:
        return <DashboardScreen />;
    }
  };

  return (
    <Layout 
      currentScreen={currentScreen} 
      onNavigate={setCurrentScreen}
      title={getTitle()}
      showBack={['customer-profile', 'notifications', 'suppliers'].includes(currentScreen)}
      onBack={() => {
        if (currentScreen === 'customer-profile') setCurrentScreen('customers');
        else if (currentScreen === 'notifications') setCurrentScreen('dashboard');
        else if (currentScreen === 'suppliers') setCurrentScreen('inventory');
      }}
    >
      <AnimatePresence mode="wait">
        <motion.div
          key={currentScreen}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }}
          transition={{ duration: 0.2 }}
          className="h-full"
        >
          {renderScreen()}
        </motion.div>
      </AnimatePresence>
    </Layout>
  );
}

