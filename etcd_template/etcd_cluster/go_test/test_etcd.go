package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"go.etcd.io/etcd/client/v3"
)

func main() {
	endpoints := []string{
		"http://localhost:2379", // nginx 代理端口
		"http://etcd-00:2379",
		"http://etcd-01:2379",
		"http://etcd-02:2379",
	}
	cli, err := clientv3.New(clientv3.Config{
		Endpoints:   endpoints,
		DialTimeout: 5 * time.Second,
	})
	if err != nil {
		log.Fatal("Failed to connect to etcd cluster:", err)
	}
	defer cli.Close()

	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	_, err = cli.Put(ctx, "cluster_key", "Hello from cluster!")
	cancel()
	if err != nil {
		log.Fatal("Failed to put key:", err)
	}
	fmt.Println("Successfully put key 'cluster_key'")

	ctx, cancel = context.WithTimeout(context.Background(), time.Second)
	resp, err := cli.Get(ctx, "cluster_key")
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

	fmt.Println("etcd cluster test finished!")
}
