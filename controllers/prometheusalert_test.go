package controllers

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGetTimeDuration(t *testing.T) {
	start := "2023-08-04T02:51:54.972Z"
	end := "2023-08-04T03:01:54.972Z"
	duration := GetTimeDuration(start, end)
	if assert.NotEqual(t, "", duration) {
		t.Log(duration)
	}
}
