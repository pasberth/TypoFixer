#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# typoを検出するデバッガ。Kernelにincludeすればプログラム全体を監視する
module TypoFixer::TypoTracker

  def typoin
    $stdin
  end

  def typoout
    $stdout
  end
  
  [:typoin, :typoout].each do |a|
    define_method :"#{a}=" do |v|
      self.class.send :define_method, a do
        v
      end
    end
  end
  
  def typo_hook e, ifn, fn, *as, &b
    if typoout
      typoout.write "もしかして: #{ifn}\n"
      $@.each do |at|
        typoout.write "\t#{at}\n"
      end
    end
    send ifn, *as, &b
  end

  def typo e, methods, funcname, *args, &blk
    typo_cases.each do |_case|
      begin
        return _case.call e, methods, funcname, *args, &blk
      rescue Exception
      end
    end

    raise e
  end

  def typo_without_receiver e, fn, *as, &b
    typo(e, methods + private_methods, fn, *as, &b)
  end

  def typo_with_receiver e, fn, *as, &b
    typo(e, methods, fn, *as, &b)
  end

  def typo_cases
    return @typo_cases if @typo_cases
    (@typo_cases = []).tap do |typo_cases|
      @typo_cases << proc do |e, methods, funcname, *args, &blk|
        most = []
        seq = funcname.to_s.split //
        seq.length.times do |i|
          t = seq.clone
          t[i] = '.'
          that = methods.grep /^#{t.join}$/
          most += that.reject { |item| most.include? item }
        end

        if most.one?
          typo_hook e, most.first, funcname, *args, &blk
        else
          raise e
        end
      end
        

      @typo_cases << proc do |e, methods, funcname, *args, &blk|
        most = []
        seq = funcname.to_s.split //
        seq.length.times do |i|
          t = seq.clone
          t[i] = '.'
          t[i+1] = '.'
          that = methods.grep /^#{t.join}$/
          most += that.reject { |item| most.include? item }
        end

        if most.one?
          typo_hook e, most.first, funcname, *args, &blk
        else
          raise e
        end
      end

      @typo_cases << proc do |e, methods, funcname, *args, &blk|
        most = []
        seq = funcname.to_s.split //
        seq.length.times do |i|
          t = seq.clone
          t.delete_at i
          t.delete_at i
          t[i] = '.{0,4}'
          that = methods.grep /^#{t.join}$/
          most += that.reject { |item| most.include? item }
        end

        if most.one?
          typo_hook e, most.first, funcname, *args, &blk
        else
          raise e
        end
      end
    end
  end

  def method_missing funcname, *args, &blk
    # システムで予約されたものはキャッチしない
    if [:to_ary, :to_path, :to_str, :to_hash, :to_int, :to_io, :to_regexp, :to_proc].include? funcname
      super
    end

    begin
      super
    rescue NameError => e # レシーバが存在しない場合
      typo_without_receiver e, funcname, *args, &blk
    rescue NoMethodError => e # レシーバが存在する場合
      typo_with_receiver e, funcname, *args, &blk
    end
  end
end