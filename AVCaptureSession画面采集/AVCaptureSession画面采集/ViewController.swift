//
//  ViewController.swift
//  AVCaptureSession画面采集
//
//  Created by 丁瑞瑞 on 8/11/16.
//  Copyright © 2016年 Rochester. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
class ViewController: UIViewController {
    // 创建录制会话对象
    fileprivate lazy var session : AVCaptureSession = AVCaptureSession()
    // 创建一个预览图层
    fileprivate lazy var preViewLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    // 创建一个全局队列
    fileprivate lazy var queue  = DispatchQueue.global()
    fileprivate lazy var audioQueue  = DispatchQueue.global()
//    fileprivate lazy var avPlay : AVPlayerViewController = {
//                return player
//    }()
    // 创建视频输入源
    fileprivate var videoInput : AVCaptureDeviceInput?
    // 创建视频输出源
    fileprivate var videoOutPut : AVCaptureVideoDataOutput?
    // 创建音频输入源
    fileprivate var audioInput : AVCaptureDeviceInput?
    // 创建音频输出源
    fileprivate var audioOutPut : AVCaptureAudioDataOutput?
    // 创建一个文件输出对象
    fileprivate var fileOutPut : AVCaptureMovieFileOutput?
    fileprivate var url1 : URL?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func clean(_ sender: AnyObject) {
        let home = NSHomeDirectory() as NSString
        let document = home.appendingPathComponent("Documents") as NSString
        
        let file = document.appendingPathComponent("xxx.mp4")
        let fileManager = FileManager.default
        let isHave = fileManager.fileExists(atPath: file)
        if isHave {
//            try? fileManager.removeItem(atPath: file){
//                return
//            }
            try! fileManager.removeItem(atPath: file)
            print("清理成功!")
        }else{
//            NSLog("啥也没有啊")
            print("清理失败!")
        }
        
    }
    @IBAction func play(_ sender: AnyObject) {
//        avPlay.player?.play()
//        [self presentViewController:avPlay animated:YES completion:nil]
        let playItem = AVPlayerItem(url: self.url1!)
        let play = AVPlayer.init(playerItem: playItem)
        let player = AVPlayerViewController()
        player.delegate = self
        player.player = play
        player.view.frame = self.view.bounds
//        self.view.addSubview(player.view)
        

        self.present(player, animated: true) { 
            player.player?.play()
        }
    }
    


}

extension ViewController{
    // 开始录制
    @IBAction func startCapture(_ sender: AnyObject) {
        // 设置视频
        setUpVideo()
        // 设置声音
        setUpAudio()
        // 创建文件写入输出
        let fileOutPut = AVCaptureMovieFileOutput()
        self.fileOutPut = fileOutPut
        self.session.addOutput(self.fileOutPut)
        
        // 给观众一个预览图层
        self.preViewLayer.frame = view.bounds
        view.layer.insertSublayer(preViewLayer, at: 0)
        // 开始录制
        self.session.startRunning()
        // 获取沙盒的地址
        let home = NSHomeDirectory() as NSString
        let document = home.appendingPathComponent("Documents") as NSString
        
        let file = document.appendingPathComponent("xxx.mp4")
//        print("home == \(url)")
//        let url = URL(string: file)
        let url = URL(fileURLWithPath: file)
        self.url1 = url
        fileOutPut.startRecording(toOutputFileURL: url, recordingDelegate: self)
    }
    // 停止录制
    @IBAction func stopCapture(_ sender: AnyObject) {
        self.session.stopRunning()
        self.preViewLayer.removeFromSuperlayer()
        self.fileOutPut?.stopRecording()
        // 移除输入源和舒楚媛
        self.session.removeInput(self.videoInput)
        self.session.removeOutput(self.videoOutPut)
        self.session.removeInput(self.audioInput)
        self.session.removeOutput(self.audioOutPut)
        self.session.removeOutput(self.fileOutPut)
    }
    // 旋转镜头
    @IBAction func rotateCamera(_ sender: AnyObject) {
        let rotaionAnim = CATransition()
        rotaionAnim.type = "oglFlip"
        rotaionAnim.subtype = "fromLeft"
        rotaionAnim.duration = 0.5
        view.layer.add(rotaionAnim, forKey: nil)
        // 获取之前的镜头
        guard var position = self.videoInput?.device.position else {return}
        // 设置相反的位置的镜头
        position = position == .front ? .back : .front
        // 根据现在摄像头的位置创建新的device
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice]
        guard let device = devices?.filter({$0.position == position}).first else {return}
        // 创建新的输入源
        guard let input = try? AVCaptureDeviceInput(device: device) else {return}
        // 在session中切换input
        session.beginConfiguration()
        session.removeInput(self.videoInput)
        if session.canAddInput(self.videoInput) {
            session.addInput(input)

        }
        self.videoInput = input
        session.commitConfiguration()
        
        
    }
    
    
    
}
extension ViewController{
    fileprivate func setUpVideo(){
        // 会话输入源(获取摄像头)
        // 获取设备
        guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] else {
            print("模拟器无效")
            
            return
        }
        // 获取前置摄像头
        guard let deviece = devices.filter({ $0.position == .front }).first else {
            return
        }
        // 获取AVCaptureDeviceInput 输入源
        guard let input : AVCaptureDeviceInput = try? AVCaptureDeviceInput(device: deviece) else {
            return
        }
        // 设置视频输入源 全局变量
        self.videoInput = input
        // 判断视频会话对象是否能添加输入源
        if self.session.canAddInput(input){
          self.session.addInput(input)
        }
        
        
        // 会话输出源
        let outPut : AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        // 设置输出源的代理
        outPut.setSampleBufferDelegate(self, queue: self.queue)
        
        // 判断视频录制会话对象是否能添加输出源
        if self.session.canAddOutput(outPut){
            self.session.addOutput(outPut)
        }
        self.videoOutPut = outPut
    }
    fileprivate func setUpAudio(){
        // 创建音频输入源(话筒)
        // 获取设备
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio) else {return}
        // 创建输入源
        guard let input = try? AVCaptureDeviceInput(device: device) else {return}
        self.audioInput = input
        // 判断是否能添加输入源
        if session.canAddInput(input) {
            session.addInput(input)
        }
        // 创建输出源
        let outPut = AVCaptureAudioDataOutput()
        // 设置代理
        outPut.setSampleBufferDelegate(self, queue: self.audioQueue)
        self.audioOutPut = outPut
        // 判断是否能添加输出源
        if session.canAddOutput(outPut){
            session.addOutput(outPut)
        }
//        connection = outPut.connection(withMediaType: AVMediaTypeAudio)
//        self.videoOutPut = outPut
        
    }
    
}
// 遵守录制视频输出会话的代理
extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate{
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if connection == self.videoOutPut?.connection(withMediaType: AVMediaTypeVideo) {
            print("输出视频画面")
        }else{
            print("获取音频!")
        }
    }
    
}

extension ViewController : AVCaptureFileOutputRecordingDelegate{
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        print("开始写入")
    }
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("停止写入")
    }
}

extension ViewController : AVPlayerViewControllerDelegate{
    
}
