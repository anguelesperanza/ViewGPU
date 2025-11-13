package main

import "core:fmt"
import "vendor:wgpu"
import "base:runtime"

import "core:c/libc"

state: struct {
	ctx:            runtime.Context,

	// All of the below are of type: distinct rawptr
	instance:       wgpu.Instance,
	adapter:        wgpu.Adapter, 
	device:         wgpu.Device,
	adapter_info: wgpu.AdapterInfo,
	status: wgpu.Status,
}


on_device :: proc "c" (status: wgpu.RequestDeviceStatus, device: wgpu.Device, message: string, userdata1, userdata2: rawptr) {
		context = state.ctx
		if status != .Success || device == nil {
			fmt.panicf("request device failure: [%v] %s", status, message)
		}
		state.device = device
}

on_adapter :: proc "c" (status: wgpu.RequestAdapterStatus, adapter: wgpu.Adapter, message:wgpu.StringView, userdata1:rawptr, userdata2:rawptr){
	/*Requesting an instance adapater requires a callback proc
	This is that callbakc proc*/
	context = state.ctx
	if status != .Success || adapter == nil {
		fmt.panicf("Request Adapter Failure: [%v] %s", status, message)
	}

	state.adapter = adapter
}

main :: proc() {
	state.instance = wgpu.CreateInstance()// -> Instance

	if state.instance == nil {
		panic("Could not create instance!")
	} 

	wgpu.InstanceRequestAdapter(
		instance = state.instance,
		options = nil,
		callbackInfo = {callback = on_adapter},
	)
	 
	wgpu.AdapterRequestDevice(
		adapter = state.adapter,
		descriptor = nil,
		callbackInfo = {callback = on_device},
	)

	info, status := wgpu.AdapterGetInfo(adapter = state.adapter)

	if status == .Error {
		panic("Cannot get adapter information.")
	}

	fmt.printf("GPU Driver: %s\n",info.vendor)
	fmt.printf("GPU Name: %s\n", info.device)
	fmt.printf("GPU Type: %s\n",info.adapterType)
	fmt.printf("GPU Vendor ID: %v\n", info.vendorID)
	fmt.printf("GPU Device ID: %v\n", info.deviceID)

	wgpu.DeviceRelease(device = state.device)
	wgpu.AdapterRelease(adapter = state.adapter)
	wgpu.InstanceRelease(instance = state.instance)

	fmt.println("Press Enter to close")
	libc.getchar()

}

