package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"go.etcd.io/etcd/client/v3"
)

func main() {
	cli, err := clientv3.New(clientv3.Config{
		Endpoints:   []string{"http://localhost:2379"},
		DialTimeout: 5 * time.Second,
	})
	if err != nil {
		log.Fatal("Failed to connect to etcd:", err)
	}
	defer cli.Close()

	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	_, err = cli.Put(ctx, "test_key", "Hello from single node!")
	cancel()
	if err != nil {
		log.Fatal("Failed to put key:", err)
	}
	fmt.Println("Successfully put key 'test_key'")

	ctx, cancel = context.WithTimeout(context.Background(), time.Second)
	resp, err := cli.Get(ctx, "test_key")
	cancel()
	if err != nil {
		log.Fatal("Failed to get key:", err)
	}

	if len(resp.Kvs) == 0 {
		fmt.Println("No key found")
	} else {
		for _, ev := range resp.Kvs {
			fmt.Printf("Key: %s, Value: %s\n", string(ev.Key), string(ev.Value))
		}
	}

	fmt.Println("etcd single node test finished!")
}
