extends Node
class_name VoipInstance

signal received_voice_data
signal send_voice_data
signal _updated_sample_format

export var custom_voice_audio_stream_player: NodePath

var recording: bool = false

var voip_format: int = 0
var voip_mix_rate: int = 44100
var voip_stereo: bool = false

var _microphone: VoipMicrophone
var _voice
var _effect_capture: AudioEffectCapture

func _ready() -> void:
	_microphone = VoipMicrophone.new()
	add_child(_microphone)

	if !custom_voice_audio_stream_player.is_empty():
		var player = get_node(custom_voice_audio_stream_player)
		if player != null:
			if player is AudioStreamPlayer || player is AudioStreamPlayer2D || player is AudioStreamPlayer3D:
				_voice = player
			else:
				push_error("voip_isntance.gd: node:'%s' is not any kind of AudioStreamPlayer!" % custom_voice_audio_stream_player)
		else:
			push_error("voip_isntance.gd: node:'%s' does not exist!" % custom_voice_audio_stream_player)
	else:
		_voice = AudioStreamPlayer.new()
		add_child(_voice)

	var record_bus_idx = AudioServer.get_bus_index(_microphone.bus)

	_effect_capture = AudioServer.get_bus_effect(record_bus_idx, 0)

remote func _speak(sample_data: PoolByteArray, id: int = -1):
	emit_signal("received_voice_data", sample_data, id)

	var sample = AudioStreamSample.new()
	sample.data = sample_data

	sample.set_format(voip_format)
	sample.set_mix_rate(voip_mix_rate)
	sample.set_stereo(voip_stereo)

	_voice.stream = sample
	_voice.play()

func _process(delta: float) -> void:
	if recording:
		var stereo_data = _effect_capture.get_buffer(_effect_capture.get_frames_available())
		if stereo_data.size() > 0:
			var data = PoolByteArray()
			for frame in stereo_data:
				var v = clamp(frame.x * 128, -128, 127)
				data.append(v)

			rpc_unreliable("_speak", data,  get_tree().get_network_unique_id())
			emit_signal("send_voice_data", data)





