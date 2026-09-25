import React, { useEffect, useState } from 'react';
import { Text } from 'react-native';
import { FlashList } from '@shopify/flash-list';
import { format } from 'date-fns';

export default function OrdersScreen() {
  const [orders, setOrders] = useState<any[]>([]);
  useEffect(() => {
    const t = setInterval(() => {
      fetch('https://api.shopfront.example/orders').then(r => r.json()).then(setOrders);
    }, 5000);
    return () => clearInterval(t);
  }, []);
  return (
    <FlashList
      data={orders}
      estimatedItemSize={48}
      keyExtractor={o => o.id}
      renderItem={({ item }) => <Text>{item.id} · {format(new Date(item.createdAt), 'PP')}</Text>}
    />
  );
}
