# -*- coding: utf-8 -*-
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: transcription.proto
# Protobuf Python Version: 4.25.0
"""Generated protocol buffer code."""
from google.protobuf import descriptor as _descriptor
from google.protobuf import descriptor_pool as _descriptor_pool
from google.protobuf import symbol_database as _symbol_database
from google.protobuf.internal import builder as _builder
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()


from google.protobuf import timestamp_pb2 as google_dot_protobuf_dot_timestamp__pb2


DESCRIPTOR = _descriptor_pool.Default().AddSerializedFile(b'\n\x13transcription.proto\x12\x14sigper.transcription\x1a\x1fgoogle/protobuf/timestamp.proto\"X\n\x13\x41udioSegmentRequest\x12\x12\n\naudio_data\x18\x01 \x01(\x0c\x12-\n\tsend_time\x18\x02 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\"\x9a\x01\n\x12TranscriptResponse\x12\x15\n\rtranscription\x18\x01 \x01(\t\x12\x0f\n\x07seq_num\x18\x02 \x01(\x05\x12.\n\nstart_time\x18\x03 \x01(\x0b\x32\x1a.google.protobuf.Timestamp\x12,\n\x08\x65nd_time\x18\x04 \x01(\x0b\x32\x1a.google.protobuf.Timestamp2\x82\x01\n\x12\x41udioTranscription\x12l\n\x0fTranscribeAudio\x12).sigper.transcription.AudioSegmentRequest\x1a(.sigper.transcription.TranscriptResponse\"\x00(\x01\x30\x01\x62\x06proto3')

_globals = globals()
_builder.BuildMessageAndEnumDescriptors(DESCRIPTOR, _globals)
_builder.BuildTopDescriptorsAndMessages(DESCRIPTOR, 'transcription_pb2', _globals)
if _descriptor._USE_C_DESCRIPTORS == False:
  DESCRIPTOR._options = None
  _globals['_AUDIOSEGMENTREQUEST']._serialized_start=78
  _globals['_AUDIOSEGMENTREQUEST']._serialized_end=166
  _globals['_TRANSCRIPTRESPONSE']._serialized_start=169
  _globals['_TRANSCRIPTRESPONSE']._serialized_end=323
  _globals['_AUDIOTRANSCRIPTION']._serialized_start=326
  _globals['_AUDIOTRANSCRIPTION']._serialized_end=456
# @@protoc_insertion_point(module_scope)
