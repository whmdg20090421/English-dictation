import { useEffect } from 'react';
import { db } from './db';

// To simulate an actual API call
const mockApiCall = async (action: string, payload: any) => {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      // 80% chance of success
      if (Math.random() > 0.2) {
        resolve({ success: true });
      } else {
        reject(new Error("Network Error or Server Down"));
      }
    }, 1000);
  });
};

export function useSyncQueue() {
  useEffect(() => {
    let interval: NodeJS.Timeout;

    const processQueue = async () => {
      // Check network status (mocked or real)
      // We will skip netinfo if it's not installed, let's just assume we try anyway 
      // or we can just rely on the mockApiCall simulating failure.
      
      try {
        const pendingItems = db.getAllSync<{id: number, action: string, payload: string}>(
          `SELECT id, action, payload FROM SyncQueue WHERE status = 'pending' LIMIT 5;`
        );

        if (pendingItems.length === 0) return;

        console.log(`[SyncQueue] Found ${pendingItems.length} pending items. Attempting sync...`);

        for (const item of pendingItems) {
          try {
            const payload = item.payload ? JSON.parse(item.payload) : {};
            await mockApiCall(item.action, payload);
            
            // Mark as completed
            db.runSync(`UPDATE SyncQueue SET status = 'completed' WHERE id = ?`, item.id);
            console.log(`[SyncQueue] Successfully synced item ${item.id} (${item.action})`);
          } catch (error) {
            console.log(`[SyncQueue] Failed to sync item ${item.id} (${item.action}):`, error);
            // Optionally we can update a retry_count here, but keeping it pending is enough for mock
          }
        }
      } catch (error) {
        console.error('[SyncQueue] Error processing queue:', error);
      }
    };

    // Run every 10 seconds
    interval = setInterval(processQueue, 10000);
    // Also run immediately on mount
    processQueue();

    return () => clearInterval(interval);
  }, []);
}
