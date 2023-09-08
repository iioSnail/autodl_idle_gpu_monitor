#!/usr/bin/env python

import argparse
import json
import os
import time

import GPUtil
import requests

GPUs = GPUtil.getGPUs()

if len(GPUs) <= 0:
    print("无GPU！无需监控！")
    exit(0)

gpu_name = GPUs[0].name


def gpu_is_idle():
    for gpu in GPUs:
        # gpu.load = GPU使用率
        if gpu.load > 0:
            print("GPU利用率：%s%%" % (gpu.load * 100))
            return False
    return True


def check_wechat_notify(args):
    headers = {"Authorization": args.token}
    resp = requests.post("https://www.autodl.com/api/v1/wechat/message/send",
                         json={
                             "title": "GPU闲置监控",
                             "name": "%s启动闲置监控" % gpu_name,
                             "content": "%s启动闲置监控" % gpu_name
                         }, headers=headers)

    try:
        if not resp.ok:
            return False

        return json.loads(resp.content.decode())['code'] == 'Success'
    except:
        print(resp.content.decode())
        return False


def notify_wechat(args):
    print("闲置时间过久，通知微信")
    headers = {"Authorization": args.token}

    content = "%s闲置超过%d分钟！" % (gpu_name, args.max_idle)
    if args.shutdown:
        content += "系统将在%d分钟后关机！" % args.wait_time

    resp = requests.post("https://www.autodl.com/api/v1/wechat/message/send",
                         json={
                             "title": "GPU闲置通知",
                             "name": content,
                             "content": content
                         }, headers=headers)

    try:
        if not resp.ok:
            return False

        return json.loads(resp.content.decode())['code'] == 'Success'
    except:
        print(resp.content.decode())
        return False


def main():
    args = parse_args()

    max_idle = args.max_idle  # 最大闲置时长（单位秒）

    max_idle *= 60
    # 记录上次使用gpu的时间
    last_time = time.time()

    while True:
        time.sleep(10)  # 每10s检测一次gpu使用情况

        if not gpu_is_idle():
            # GPU还在使用
            last_time = time.time()
            continue

        idle_time = int(time.time() - last_time)
        print("GPU闲置时长:", idle_time, "秒")

        if idle_time < max_idle:
            # 未达到最大闲置时长
            continue

        print("达到最大闲置时长")

        # 达到闲置时长，通知微信
        # https://www.autodl.com/docs/msg/
        notify_wechat(args)
        # 重置时间，{max_idle}分钟后再次提醒
        last_time = time.time()

        if args.shutdown:
            print("已通知微信，系统将在%d分钟后关机" % args.wait_time)

            time.sleep(args.wait_time * 60)

            print("关机")
            os.system("shutdown")


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', '--token', type=str, default=None,
                        help='开发者Token，用于微信通知。详见：https://www.autodl.com/docs/msg/')
    parser.add_argument('-c', '--check-token', action='store_true', default=False,
                        help='是否验证Token。验证Token会在启动时发送一条消息可正常发送!')
    parser.add_argument('-m', '--max-idle', type=int, default=10,
                        help='最大闲置时长（分钟）')
    parser.add_argument('-s', '--shutdown', action='store_true', default=False,
                        help='是否自动关机')
    parser.add_argument('-w', '--wait-time', type=int, default=10,
                        help='等待时长（分钟）。通知微信后，等待一段时间后关机')

    args = parser.parse_known_args()[0]

    if args.max_idle <= 0:
        print("max-idle必须大于0分钟")
        exit(0)

    if args.token is None:
        print("Token为空！GPU闲置时将不会进行微信通知!")

    if args.token and args.check_token:
        if check_wechat_notify(args):
            print("微信通知配置成功!")
        else:
            print("微信通知配置失败，请检测Token是否正确！")

    if args.shutdown:
        print("自动关机开启！当GPU闲置时长达到%d+%d=%d分钟后将会自动关机！" \
              % (args.max_idle, args.wait_time, args.max_idle + args.wait_time))

    return args


if __name__ == '__main__':
    main()
