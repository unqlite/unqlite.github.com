#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
my $date = sprintf("%04d-%02d-%02d", $year+1900, $mon+1, $mday);
my $post = sprintf("./_posts/%s-%02d-%02d-%02d-default-title.md", $date, $hour, $min, $sec);

open my $out, ">:utf8", "$post" or
	die "Can't open $post for writing: $!\n";

print $out <<_EOC_;
---
layout: post
title: 待定标题
date: $date
categories:
  - 技术
tags:
  - 待定标签
---
## 主题简介


## 扩展阅读


## 祝大家玩的开心

_EOC_

close $out;

