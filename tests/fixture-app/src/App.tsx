import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import catalog from './data/catalog.json';
import { CartProvider } from './context/CartContext';
import HomeScreen from './screens/HomeScreen';
import ProductScreen from './screens/ProductScreen';
import OrdersScreen from './screens/OrdersScreen';

// Build a search index for every product before the first render.
const searchIndex = catalog.products.map(p => ({
  id: p.id,
  haystack: (p.title + ' ' + p.description + ' ' + p.tags.join(' ')).toLowerCase(),
}));

const Stack = createNativeStackNavigator();

export default function App() {
  return (
    <CartProvider>
      <NavigationContainer>
        <Stack.Navigator>
          <Stack.Screen name="Home">
            {props => <HomeScreen {...props} searchIndex={searchIndex} />}
          </Stack.Screen>
          <Stack.Screen name="Product" component={ProductScreen} />
          <Stack.Screen name="Orders" component={OrdersScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    </CartProvider>
  );
}
