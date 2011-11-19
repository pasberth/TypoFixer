#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# typoを検出するデバッガ。Kernelにincludeすればプログラム全体を監視する
module TypoFixer::TypoTracker

  alias typofixer_original_method_missing method_missing

  private 

  def typoin
    $stdin
  end

  def typoout
    $stdout
  end

  def typo_hook e, ifn, fn, *as, &b
    typoout.write "もしかして: #{ifn}\n"
    $@.each do |at|
      typoout.write "\t#{at}\n"
    end
    send ifn, *as, &b
  end

  def typo_hook_without_receiver e, fn, *as, &b
    typo(e, methods + private_methods, fn, *as, &b)
  end


  def typo_hook_with_receiver e, fn, *as, &b
    typo(e, methods, fn, *as, &b)        
  end

  def typo e, methods, funcname, *args, &blk
    seq = funcname.to_s.split //
    most = []
    seq.length.times do |i|
      t = seq.clone
      t[i] = '.'
      that = methods.grep /^#{t.join}$/
      next if that.empty?
      most += that
    end

    return typo_hook e, most.first, funcname, *args, &blk unless most.empty?

    seq.length.times do |i|
      t = seq.clone
      t[i] = '.'
      t[i+1] = '.'
      that = methods.grep /^#{t.join}$/
      next if that.empty?
      most += that
    end

    return typo_hook e, most.first, funcname, *args, &blk unless most.empty?

    raise e
  end

  def method_missing funcname, *args, &blk
    # システムで予約されたものはキャッチしない
    if [:to_ary, :to_path, :to_str, :to_hash, :to_int, :to_io, :to_regexp, :to_proc].include? funcname
      super
    end

    begin
      super
    rescue NameError => e # レシーバが存在しない場合
      typo_hook_without_receiver e, funcname, *args, &blk
    rescue NoMethodError => e # レシーバが存在する場合
      typo_hook_with_receiver e, funcname, *args, &blk
    end
  end
end