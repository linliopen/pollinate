package com.example.entity;

import java.util.Date;
import java.io.Serializable;


public class Items implements Serializable {
    private static final long serialVersionUID = 262562090146016708L;
    
    private Integer id;

    private Date createtime;


    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Date getCreatetime() {
        return createtime;
    }

    public void setCreatetime(Date createtime) {
        this.createtime = createtime;
    }

}