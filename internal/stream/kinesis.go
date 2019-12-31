package stream

import (
	"context"
)

type Stream struct {
	*Kinesis
	counter uint64
}

func NewStream(streamName string, region string) KinesisProvider {
	s := &Stream{Kinesis: NewKinesis(streamName, region)}
	return s
}

func (s *Stream) PutBytes(ctx context.Context, buff []byte, channel string) error {
	// using channel as a shard key so in order delivery of those messages is guaranteed
	return s.Put(ctx, channel, buff)
}
