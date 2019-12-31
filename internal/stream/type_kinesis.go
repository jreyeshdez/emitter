package stream

import (
	"context"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/kinesis"
	awstrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/aws/aws-sdk-go/aws"
)

type KinesisProvider interface {
	PutBytes(ctx context.Context, buff []byte, channel string) error
}

// A standardized way to create/interact with Kinesis streams
type Kinesis struct {
	StreamName string
	Connection *kinesis.Kinesis
}

func NewKinesis(streamName string, region string) *Kinesis {
	if region == "" {
		panic("aws region must be specified")
	}

	config := aws.Config{
		Region: aws.String(region),
	}
	sess := session.Must(session.NewSession(&config))
	sess = awstrace.WrapSession(sess)
	conn := kinesis.New(sess)
	return &Kinesis{StreamName: streamName, Connection: conn}
}

func (k *Kinesis) Put(ctx context.Context, partitionKey string, payload []byte) error {
	var input kinesis.PutRecordInput
	input.SetStreamName(k.StreamName)
	input.SetPartitionKey(partitionKey)
	input.SetData(payload)
	_, err := k.Connection.PutRecordWithContext(ctx, &input)
	return err
}
